# Calculate proportion of time spent at home vs work vs outdoors vs travelling

Based on travel time (input variable by user). Assumes a fixed ratio of
time spent at home vs at work vs outdoors.

## Usage

``` r
location_props(travel_time, home_prop, work_prop, outd_prop)
```

## Arguments

- travel_time:

  daily time spent travelling / commuting in seconds (s)

- home_prop:

  proportion of time spent at home WITHOUT considering commute

- work_prop:

  proportion of time spent at work WITHOUT considering commute

- outd_prop:

  proportion of time spent outside WITHOUT considering commute

## Value

List with following elements: "travel", "home", "work", "out",
corresponding value is the proportion of time spent in each location.

## Details

We assume that the time spent commuting takes away from time spent at
home, but not the time spent at work or outdoors.
