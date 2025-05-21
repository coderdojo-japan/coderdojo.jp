# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

# MarkdownファイルのMIMEタイプを設定
Mime::Type.register 'text/markdown', :md, %w( text/plain )
Rack::Mime::MIME_TYPES['.md'] = 'text/markdown; charset=utf-8'
