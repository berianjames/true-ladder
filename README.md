A balanced Premier League table
===============================

A score ladder is the most crucial data summary in any professional sport. For many of us, it is the only data presentation we will look at for a sport, and we will check it frequently. 

However, in round-robin sports, where each team will play every other team a fixed number of times during the competition, the score ladder
at a given moment suffers from the bias that some teams may have had their tougher games behind them (and have a lower current score), while others may have games against tougher competition ahead.

This project builds a reweighted ladder that is free from this bias, giving the most accurate current depiction of the state of the competition.

Impact
-------

Here's a example: have a look at the [current English Premier League table](http://www.premierleague.com/en-gb/matchday/league-table.html). Though it isn't obvious, some teams are acutally falsely higher than they should be, by virtue of the order in which they have been playing their games. *But which ones?*

For the table as at January 21, 2013:

![Rebalanced Premier League table](https://raw.github.com/berianjames/true-ladder/master/table-snapshot.png)

For these data, the most important effects are that West Brom is moved down relative to its standing in the unweighted table, and Wigan is moved up.

How does it work?
-----------------

We can infer from the results produced so far how tough the competition has been for each team. When all teams are due to play one another, we should reweight the raw scores to account for the strength of their opponents. In this case, we compute the performance of each team relative to the mean of all teams in the competition, modeling home and away games separately.

Then, for each team, we reweight the points score in home games by the average strength of their opponents relative to the strength of all teams in the competition. And, the same is done for points scored in away games. The sum of the reweighted home game points and away game points gives the reweighted table.

A deficiency of the current implementation is that top-ranked teams may be artificially weighted down as their competition will be weaker than those of other teams by virtue of their being unable to play against themselves. The same effect holds in reverse at the other end of the table. This is not a substantial concern, and it could be addressed by making the weightings for home and away games for each team not relative to all the teams in the competition, but relative to all the teams they could potentially play.


Getting started yourself
------------------------

The repository includes data current as of January 20, 2013. To use these data as a starting point, import the SQL dump

	>> mysql -e 'CREATE DATABASE premier_league;'
	>> mysql premier_league < premier_league_2013-01-21.sql
	
The resulting table `results_2013_01_20` contains detail of matches played this season, though not matches that are yet to be played. The raw data file contains many fields of betting odds that are not used for prediction in this work.

The analysis is handled by queries contained in `league_table_reweighting.sql`, and can be executed as follows:

	>> mysql < league_table_reweighting.sql

This produces the final output table (`current_table_rebalanced`) as well as several intermediate tables used in the analysis.

Keeping up to date
------------------

As new games as played, the raw input data file will be updated [here](http://www.football-data.co.uk/mmz4281/1213/E0.csv), with its schema preserved. 

Disclaimer
----------

This analysis and the alogrithm for performing it were all carried out with a blind eye to the reweighting that resulted. Nevertheless, it behooves us to note that the Swansea Associated Football Club are (deserving) beneficiaries of this scheme.
