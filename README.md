# JARBS

## Opinionated Lambda Tooling

![Jarbs](http://d.pr/i/12xTT/45aKDrvM+)

## Install

Currently we distributed the `jarbs` runtime via gems hosted by RubyGems.org.

`gem install jarbs`

If this is a new machine or you haven't had to install any C extentions for Ruby yet, you may also need `cmake` before this gem will install: `brew install cmake`. We're looking at options for eliminating this step.

## Usage

For the most up-to-date documentation and usage, run `jarbs -h`

### Generate a new lambda project:

`lambda new my-function`

This produces:

```
- my-function/
  package.json (for build and dev deps)
  - lambdas/
    - my-function/
      - src/
        index.js (placeholder handler function)
        package.json (for lambda dependencies)
```

### Generate another lambda in the same project

(while in the project folder created above):

`lambda new other-function`

Your project will then look like:

```
- my-function/
  package.json
  - lambdas/
    - my-function/
      - src/
        index.js
        package.json
    - other-function/
      - src/
        index.js
        package.json
```

### Deploy to Lambda

`jarbs deploy my-function`

You can provide the ARN role via `--role` at invocation, or it will ask you for one during runtime. This will perform the following:

1. Build code using [BabelJS](http://babeljs.io/) via the default `npm build:function` step as defined in the function's `package.json`. This build step also copies the compiled code from `src` to `dest`. If you customize the `npm build:function` step, the customization will also need to perform this same copy.
2. Install npm dependecies via `npm install --production` in the `dest` directory.
3. Package the `dest` dir as a zip archive (in memory).
4. Upload to S3
5. Destroy `dest` artifacts.

If you have already deployed this function to lambda before, it will update the code with your changes.

All functions are prefixed with the `--env` provided (i.e. 'dev', 'prod'). The env defaults to 'dev'.

### Remove from Lambda

`jarbs rm my-function`

Will destroy the lambda function on AWS (will still leave files in your lambdas directory). You can specify multiple functions here if you wish.

## License

*MIT*

