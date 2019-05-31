Scoping
================

So, [part of a function I
have](https://github.com/achafetz/PartnerProgress/blob/master/R/include_nn_targets.R)
essentially creates a gap that needs to be made up.

Essentially it looks at what was achieved last year (`achv`) with what
the targets are this year (`trgt`).

Here’s a sample data frame to use.

``` r
#dependencies
library(dplyr)
library(tibble)
```

``` r
#create a dummy dataset for testing
  set.seed(42)
  (test <- tibble(site = LETTERS[1:5],
                  achv = sample(1:3, 5, replace = TRUE),
                  trgt = sample(4:6, 5, replace = TRUE)))
```

    ## # A tibble: 5 x 3
    ##   site   achv  trgt
    ##   <chr> <int> <int>
    ## 1 A         3     5
    ## 2 B         3     6
    ## 3 C         1     4
    ## 4 D         3     5
    ## 5 E         2     6

The function I have created and used in the past figures out from the
current dataset what the most recent period (and then finds that year’s
target, `trgt`) and then what is the prior fiscal year to determine what
was those results are (`achv`). Its dynamic which is ideal that I never
have to manually change anything here. This worked using NSE under the
old version of `dplyr::mutate_()`.

``` r
#old function worked like this
#another function figured out the current/prior fiscal year and then identified the varaibles; here I'll just write it manually
  curr_trgt <- "trgt"
  prior_q4 <- "achv"


#the gap formula that will be passed into `mutate_()` to create the new variable
  fcn <- paste0(curr_trgt, "-", prior_q4)

  mutate_(test, .dots = setNames(fcn, "gap"))
```

    ## Warning: mutate_() is deprecated. 
    ## Please use mutate() instead
    ## 
    ## The 'programming' vignette or the tidyeval book can help you
    ## to program with mutate() : https://tidyeval.tidyverse.org
    ## This warning is displayed once per session.

    ## # A tibble: 5 x 4
    ##   site   achv  trgt   gap
    ##   <chr> <int> <int> <int>
    ## 1 A         3     5     2
    ## 2 B         3     6     3
    ## 3 C         1     4     3
    ## 4 D         3     5     2
    ## 5 E         2     6     4

You’ll note the nice warning message that `mutate_() is deprecated.` and
`Please use mutate() instead`. Depricating `mutate_()` means I can go on
using this for a short time, but will need to figure out the new
solulation using NSE.

I tried testing out the `mutate()` by just passing in one variable to
see if I could get that to work before getting the basic gap function to
work. No
dice.

``` r
#testing, but didn't think this would work since its not using any quosures
  dplyr::mutate(test, gap = curr_trgt)
```

    ## # A tibble: 5 x 4
    ##   site   achv  trgt gap  
    ##   <chr> <int> <int> <chr>
    ## 1 A         3     5 trgt 
    ## 2 B         3     6 trgt 
    ## 3 C         1     4 trgt 
    ## 4 D         3     5 trgt 
    ## 5 E         2     6 trgt

``` r
#testing, since trgt is quoted, maybe I just need to unquote it
  curr_trgt
```

    ## [1] "trgt"

``` r
  dplyr::mutate(test, gap = curr_trgt)
```

    ## # A tibble: 5 x 4
    ##   site   achv  trgt gap  
    ##   <chr> <int> <int> <chr>
    ## 1 A         3     5 trgt 
    ## 2 B         3     6 trgt 
    ## 3 C         1     4 trgt 
    ## 4 D         3     5 trgt 
    ## 5 E         2     6 trgt

``` r
#testing, with quo and then unquoting it
  quo(curr_trgt)
```

    ## <quosure>
    ## expr: ^curr_trgt
    ## env:  global

``` r
  curr_trgt_quo <- quo(curr_trgt)
  dplyr::mutate(test, gap = !!curr_trgt)
```

    ## # A tibble: 5 x 4
    ##   site   achv  trgt gap  
    ##   <chr> <int> <int> <chr>
    ## 1 A         3     5 trgt 
    ## 2 B         3     6 trgt 
    ## 3 C         1     4 trgt 
    ## 4 D         3     5 trgt 
    ## 5 E         2     6 trgt

``` r
#testing, with enquo and then unquoting it
  enquo(curr_trgt)
```

    ## <quosure>
    ## expr: ^"trgt"
    ## env:  empty

``` r
  curr_trgt_enquo <- enquo(curr_trgt)
  dplyr::mutate(test, gap = !!curr_trgt_enquo) 
```

    ## # A tibble: 5 x 4
    ##   site   achv  trgt gap  
    ##   <chr> <int> <int> <chr>
    ## 1 A         3     5 trgt 
    ## 2 B         3     6 trgt 
    ## 3 C         1     4 trgt 
    ## 4 D         3     5 trgt 
    ## 5 E         2     6 trgt

I figured those should work as they work if I were using it in
`group_by()` or passing into `mutate_at(vars(x), sum)`. So, clearly R is
not getting that `curr_trgt` is a variable name.

``` r
 #testing, with sym and then unquoting it
  sym(curr_trgt)
```

    ## trgt

``` r
  curr_trgt_sym <- sym(curr_trgt)
  dplyr::mutate(test, gap = !!curr_trgt_sym)
```

    ## # A tibble: 5 x 4
    ##   site   achv  trgt   gap
    ##   <chr> <int> <int> <int>
    ## 1 A         3     5     5
    ## 2 B         3     6     6
    ## 3 C         1     4     4
    ## 4 D         3     5     5
    ## 5 E         2     6     6

``` r
  prior_q4_sym <- sym(prior_q4)
  dplyr::mutate(test, gap = !!curr_trgt_sym  - !!prior_q4_sym) 
```

    ## # A tibble: 5 x 4
    ##   site   achv  trgt   gap
    ##   <chr> <int> <int> <int>
    ## 1 A         3     5     2
    ## 2 B         3     6     3
    ## 3 C         1     4     3
    ## 4 D         3     5     2
    ## 5 E         2     6     4

**HUZZAH\!**
