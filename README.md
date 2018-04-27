# personal_scores
Prediction of missing personal scores in video quality assessment tasks

This is basically a simple collaborative filtering scheme that was initially created for predicting missing
scores in video quality assessment studies. The idea was to improve the accuracy of MOS in cases where some
users have rated only a subset of items (e.g. video sequences).

There are three files included in this package: PredictPersonalRatings.m is a Matlab implementation of the
scheme. PredictPersonalRatings_Example.m shows a usage example. MOS_example.csv is a data file that contains
an example MOS matrix that can be used for testing.

Reference: J. Korhonen, "Predicting Personal Preferences in Subjective Video Quality Assessment," in Proc.
of QoMEX'17, Erfurt, Germany, May 2017.
