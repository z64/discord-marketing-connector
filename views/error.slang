doctype html
html
  head
    title Application
    link href="https://fonts.googleapis.com/css?family=Roboto" rel="stylesheet"
    link href="https://fonts.googleapis.com/css?family=Roboto+Mono" rel="stylesheet"

    css:
      .header {
        font-family: 'roboto';
      }

      .error {
        font-family: 'roboto mono';
      }

  body
    div.header
      h1 Error
      p
        ' Sorry, something went wrong processing your request!
      b
        ' Please
        a href="mailto:zachnowicki@gmail.com" contact the developer
        ' with the information below this line:
    hr
    div.error
      h3 Request
      p = "#{ctx.request.method} #{ctx.request.resource}"
      p = Time.new.to_s
      p = ctx.request.headers["User-Agent"]

      h3 Exception
      pre = ex.inspect_with_backtrace
