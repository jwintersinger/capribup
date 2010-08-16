Capribup
========

A backup script.
----------------

Capribup is a backup script capable of archiving directory trees or PostgreSQL
databases. Intended to be run periodically as a cronjob, Capribup has the user
specify a ruleset describing by age what backups should be kept.  It thus
avoids the pitfall common to many simple backup systems, in which only a few of
the most recent backups are kept, meaning that an error introduced into your
data that predates your most recent backup is unrecoverable. Capribup instead
encourages the user to retain more extensive backups -- one can, for example,
keep a backup from six months ago, one from a month ago, and ones from each of
the last five days.

Though Capribup is limited to backing up directory trees and PostgreSQL
databases, it could easily be extended to also deal with other data sources.
The name is derived from the notion of a capricious backup agent, which I
always found inordinately amusing, given that capricousness would perhaps be
one of the least desireable qualities in a backup utility.
