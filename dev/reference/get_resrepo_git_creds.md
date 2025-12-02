# Get git credentials if they are available

This function checks the current git remote URL and determines if the
credentials are set up for SSH or HTTPS access.

## Usage

``` r
get_resrepo_git_creds()
```

## Value

A list containing the type of credentials, the URL, and the GitHub PAT
if applicable.
