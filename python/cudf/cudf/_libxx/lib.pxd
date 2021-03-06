# Copyright (c) 2019-2020, NVIDIA CORPORATION.

# cython: profile=False
# distutils: language = c++
# cython: embedsignature = True
# cython: language_level = 3

from libc.stdint cimport int32_t, uint32_t
from libcpp cimport bool
from libcpp.vector cimport vector
from libcpp.memory cimport unique_ptr

from rmm._lib.device_buffer cimport device_buffer, DeviceBuffer, move

cdef extern from "cudf/types.hpp" namespace "cudf" nogil:
    ctypedef int32_t size_type
    ctypedef uint32_t bitmask_type

    ctypedef enum order:
        ASCENDING "cudf::order::ASCENDING"
        DESCENDING "cudf::order::DESCENDING"

    ctypedef enum null_order:
        AFTER "cudf::null_order::AFTER"
        BEFORE "cudf::null_order::BEFORE"

    cdef enum:
        UNKNOWN_NULL_COUNT = -1

    ctypedef enum interpolation:
        LINEAR "cudf::experimental::interpolation::LINEAR"
        LOWER "cudf::experimental::interpolation::LOWER"
        HIGHER "cudf::experimental::interpolation::HIGHER"
        MIDPOINT "cudf::experimental::interpolation::MIDPOINT"
        NEAREST "cudf::experimental::interpolation::NEAREST"

    cdef enum type_id:
        EMPTY = 0
        INT8 = 1
        INT16 = 2
        INT32 = 3
        INT64 = 4
        FLOAT32 = 5
        FLOAT64 = 6
        BOOL8 = 7
        TIMESTAMP_DAYS = 8
        TIMESTAMP_SECONDS = 9
        TIMESTAMP_MILLISECONDS = 10
        TIMESTAMP_MICROSECONDS = 11
        TIMESTAMP_NANOSECONDS = 12
        DICTIONARY32 = 13
        STRING = 14
        NUM_TYPE_IDS = 15

    cdef cppclass data_type:
        data_type()
        data_type(const data_type&)
        data_type(type_id id)
        type_id id()

cdef extern from "cudf/column/column.hpp" namespace "cudf" nogil:
    cdef cppclass column_contents "cudf::column::contents":
        unique_ptr[device_buffer] data
        unique_ptr[device_buffer] null_mask
        vector[unique_ptr[column]] children

    cdef cppclass column:
        column()
        column(const column& other)
        column(data_type dtype, size_type size, device_buffer&& data)
        size_type size()
        bool has_nulls()
        data_type type()
        column_view view()
        mutable_column_view mutable_view()
        column_contents release()

cdef extern from "cudf/column/column_view.hpp" namespace "cudf" nogil:
    cdef cppclass column_view:
        column_view()
        column_view(const column_view& other)

        column_view& operator=(const column_view&)
        column_view& operator=(column_view&&)
        column_view(data_type type, size_type size, const void* data)
        column_view(data_type type, size_type size, const void* data,
                    const bitmask_type* null_mask)
        column_view(data_type type, size_type size, const void* data,
                    const bitmask_type* null_mask, size_type null_count)
        column_view(data_type type, size_type size, const void* data,
                    const bitmask_type* null_mask, size_type null_count,
                    size_type offset)
        column_view(data_type type, size_type size, const void* data,
                    const bitmask_type* null_mask, size_type null_count,
                    size_type offset, vector[column_view] children)
        T* data[T]()
        T* head[T]()
        bitmask_type* null_mask()
        size_type size()
        data_type type()
        bool nullable()
        size_type null_count()
        bool has_nulls()
        size_type offset()
        size_type num_children()
        column_view child(size_type)

    cdef cppclass mutable_column_view:
        mutable_column_view()
        mutable_column_view(const mutable_column_view&)
        mutable_column_view& operator=(const mutable_column_view&)
        mutable_column_view(data_type type, size_type size, const void* data)
        mutable_column_view(data_type type, size_type size, const void* data,
                            const bitmask_type* null_mask)
        mutable_column_view(
            data_type type, size_type size, const void* data,
            const bitmask_type* null_mask, size_type null_count
        )
        mutable_column_view(
            data_type type, size_type size, const void* data,
            const bitmask_type* null_mask, size_type null_count,
            size_type offset
        )
        mutable_column_view(
            data_type type, size_type size, const void* data,
            const bitmask_type* null_mask, size_type null_count,
            size_type offset, vector[mutable_column_view] children
        )
        T* data[T]()
        T* head[T]()
        bitmask_type* null_mask()
        size_type size()
        data_type type()
        bool nullable()
        size_type null_count()
        bool has_nulls()
        size_type offset()
        size_type num_children()
        mutable_column_view& child(size_type)

cdef extern from "cudf/table/table_view.hpp" namespace "cudf" nogil:
    cdef cppclass table_view:
        table_view()
        table_view(const vector[column_view])
        column_view column(size_type column_index)
        size_type num_columns()
        size_type num_rows()

    cdef cppclass mutable_table_view:
        mutable_table_view()
        mutable_table_view(const vector[mutable_column_view])
        mutable_column_view column(size_type column_index)
        size_type num_columns()
        size_type num_rows()

cdef extern from "cudf/table/table.hpp" namespace "cudf::experimental" nogil:
    cdef cppclass table:
        table(const table&)
        table(vector[unique_ptr[column]]&& columns)
        table(table_view)
        size_type num_columns()
        table_view view()
        mutable_table_view mutable_view()
        vector[unique_ptr[column]] release()

cdef extern from "cudf/aggregation.hpp" namespace "cudf::experimental" nogil:
    cdef cppclass aggregation:
        pass

cdef extern from "<utility>" namespace "std" nogil:
    cdef unique_ptr[column] move(unique_ptr[column])
    cdef unique_ptr[table] move(unique_ptr[table])
    cdef unique_ptr[aggregation] move(unique_ptr[aggregation])
    cdef vector[unique_ptr[column]] move(vector[unique_ptr[column]])
    cdef device_buffer move(device_buffer)
