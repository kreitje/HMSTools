###
# Copyright (c) 2011 Jeff Kreitner   hitmyserver.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###

#### HMSTools
# 
#  Classes
#
#	LOCReader - Reads Lines of Code in a given directory
#	XFDL - Decompresses xfdl files and recompresses XML files into XFDL
#	  requires: base64, zlib, stringio
####

module HMSTools

	VERSION = 0.1


	# Basic Lines Of Code reader
	# Searches through all subfolders
	# You must set the extensions to search. Takes a string, comma seperated

	class LOCReader

		@ext = []

		@blank_lines = 0
		@lines = 0
		@num_files = 0
		@total = 0

		def initialize
			@lines = @lines.to_i
			@blank_lines = @blank_lines.to_i
			@num_files = @lines.to_i
			@total = @total.to_i
		end

		def run(dir, ext = "")
			unless ext == ""
				@ext = ext.split(',')
			end

			get_files dir
			@total = @lines - @blank_lines
		end

		def get_files(dir)
	
			files = Dir.glob(dir)
			dir_path = dir.chomp("*")

			for file in files
				unless File.directory?(file)
					if @ext.include?(File.extname(file))
						read_lines file
						@num_files = @num_files+1
					end
					
				else
					get_files file+"/*"
				end

			end
		end

		def read_lines(file)
			begin
				ofile = File.new(file, "r")
				while (line = ofile.gets)
					@lines += 1
					if line.strip == ""
						@blank_lines += 1
					end
				end
				ofile.close
			rescue => err
				puts "Could not access #{err}"
			end
		end

		def print_array
			[@num_files, @total, @blank_lines, @lines]
		end

		def print_hash
			{"files" => @num_files, "loc" => @total, "bloc" => @blank_lines, "lines" => @lines}
		end

		def print_output
			print "Files: #@num_files \n"
			print "Lines of Code: #@total \n"
			print "Blank Lines: #@blank_lines \n"
			print "Total Lines: #@lines"
		end

	end

	class XFDL

		def b64decode_it(contents = nil)
			x = Base64.decode64(contents)
			return x
		end

		def b64encode_it(contents = nil)
			unless contents.nil?
				x = Base64.encode64(contents)
				return x
			end
		end

		def build_and_write_xfdl_from_directory(xmldirectory, xfdldirectory)
			@files = Dir.glob(xmldirectory)
			numfiles = 0
			numxmlfiles = 0

			for file in @files
				if File.extname(file) == ".xml"
					print "Packaging "+ File.basename(file) +" to " + File.basename(file, ".xml") +".xfdl"
					build_and_write_xfdl_from_xml(file, xfdldirectory+"/"+File.basename(file, ".xml")+".xfdl")
					print "  - Complete\n"
					numxmlfiles += 1
				end

				numfiles += 1
			end

			print "\n" + numxmlfiles.to_s + " out of " + numfiles.to_s + " were XML files and processed to the XFDL format!"
		end

		def build_and_write_xfdl_from_xml(xmlfile, xfdlfile)
			# 1. Gzip
			# 2. Base64
			# 3. Write string with mime stuff on the fist line
			# 4. Save as XFDL
	
			xml_file = ''
			b64_string = ''
			new_contents = ''

			if File.exists?(xmlfile)
				xml_file = IO.read(xmlfile).to_s
			end

			# Tell Zlib to use StringIO instead of a file.. Suck it Zlib!
			a = StringIO.new ""
	
			gz = Zlib::GzipWriter.new(a)
			gz.write xml_file
			gz.close
		
			b64_string = b64encode_it(a.string)
			new_contents = "application/vnd.xfdl;content-encoding=\"base64-gzip\"\n" + b64_string

			File.open(xfdlfile, "w") { |f| f.write(new_contents) }

		end

		def deconstruct_and_write_xml(old_filename, new_filename)

			if File.exists?(old_filename)
				enc_file = ''
				enc_file = IO.read(old_filename).to_s
				content = get_xml enc_file
				File.open(new_filename, "w") { |f| f.write(content) }
			else
				puts "File does not exist!"
				return nil
			end

		end

		def initialize
			require 'base64'
			require 'zlib'
			require 'stringio'
		end

	
		def get_xml(contents)
			b64_decoded = ''
			xml_contents = ''
		
			b64_decoded = b64decode_it(contents.lines.to_a[1..-1].join)

			# Tell Zlib to use StringIO instead of a file.. Suck it Zlib!
			a = StringIO.new b64_decoded

			gz = Zlib::GzipReader.new(a)
			xml_contents = gz.read
			gz.close

			return xml_contents
		end
	end
end