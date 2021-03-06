# Copyright (c) 2015, Groupon, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# Neither the name of GROUPON nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module Backbeat
  module Search
    class Filter
      def initialize(base)
        @base = base
      end

      def filter_for(param, default = nil, &block)
        lambda do |relation, params|
          value = params.fetch(param, default)
          if value
            block.call(relation, params.merge({ param => value }))
          else
            relation
          end
        end
      end

      def apply_filters(params, *filters)
        return [] if params.empty?
        filters.reduce(@base) do |relation, filter|
          filter.call(relation, params)
        end.distinct
      end

      def name
        filter_for(:name) do |relation, params|
          relation.where("#{relation.table_name}.name = ?", params[:name])
        end
      end

      PAGE_SIZE = 25

      def per_page
        filter_for(:per_page, PAGE_SIZE) do |relation, params|
          limit = params[:per_page].to_i
          relation.limit(limit)
        end
      end

      def page
        filter_for(:page, 1) do |relation, params|
          per_page = params.fetch(:per_page, PAGE_SIZE).to_i
          page = params[:page].to_i
          offset = (page - 1) * per_page
          relation.offset(offset)
        end
      end

      def last_id
        filter_for(:last_id) do |relation, params|
          last_id = params.fetch(:last_id)
          last_created_at = relation.unscoped.where(id: last_id).pluck(:created_at).first
          relation.where("(#{relation.table_name}.created_at, #{relation.table_name}.id) < (?, ?)", last_created_at, last_id)
        end
      end

      def current_status
        filter_for(:current_status) do |relation, params|
          relation.where(
            "nodes.current_server_status = ? OR nodes.current_client_status = ?",
            params[:current_status],
            params[:current_status]
          )
        end
      end

      def past_status
        filter_for(:past_status) do |relation, params|
          relation.joins("JOIN status_changes ON status_changes.node_id = nodes.id").where(
            "status_changes.to_status = ?",
            params[:past_status]
          )
        end
      end

      def status_start
        filter_for(:status_start) do |relation, params|
          relation.joins("JOIN status_changes ON status_changes.node_id = nodes.id")
            .where("status_changes.created_at >= ?", params[:status_start])
        end
      end

      def status_end
        filter_for(:status_end) do |relation, params|
          relation.joins("JOIN status_changes ON status_changes.node_id = nodes.id")
            .where("status_changes.created_at <= ?", params[:status_end])
        end
      end
    end
  end
end
