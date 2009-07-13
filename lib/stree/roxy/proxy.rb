# Copyright (c) 2008 Ryan Daigle

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module Stree
  module Roxy # :nodoc:all
    # The very simple proxy class that provides a basic pass-through
    # mechanism between the proxy owner and the proxy target.
    class Proxy

      alias :proxy_instance_eval :instance_eval
      alias :proxy_extend :extend

      # Make sure the proxy is as dumb as it can be.
      # Blatanly taken from Jim Wierich's BlankSlate post:
      # http://onestepback.org/index.cgi/Tech/Ruby/BlankSlate.rdoc
      instance_methods.each { |m| undef_method m unless m =~ /(^__|^proxy_|^object_id)/ }

      def initialize(owner, options, args, &block)
        @owner = owner
        @target = options[:to]
        @args = args

        # Adorn with user-provided proxy methods
        [options[:extend]].flatten.each { |ext| proxy_extend(ext) } if options[:extend]
        proxy_instance_eval &block if block_given?
      end

      def proxy_owner
        @owner
      end

      def proxy_target
        if @target.is_a?(Proc)
          @target.call(@owner)
        elsif @target.is_a?(UnboundMethod)
          bound_method = @target.bind(proxy_owner)
          bound_method.arity == 0 ? bound_method.call : bound_method.call(*@args)
        else
          @target
        end
      end

      # def inspect
      #   "#<S3::Roxy::Proxy:0x#{object_id.to_s(16)}>"
      # end

      # Delegate all method calls we don't know about to target object
      def method_missing(sym, *args, &block)
        proxy_target.__send__(sym, *args, &block)
      end
    end
  end
end
