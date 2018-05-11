# personal_scores

### Predicting personal scores for video quality assessment tasks

![Personal scores](https://jarikorhonen.github.io/personal_score.png "Personal scores")

This is basically a simple collaborative filtering scheme that was initially created for predicting missing scores in video quality assessment studies, published in QoMEX'17. The idea was to improve the accuracy of MOS in cases where some users have rated only a subset of items (e.g. video sequences). We assume that this approach could be helpful for reducing the number of participants in quality assessment studies. It could be used also for assessing the reliability of MOS results and possibly also for detecting unreliable test participants.

It should be noted that there are a lot of implementations of different collaborative filtering schemes available (at least if you are ready to switch Matlab to Python), and some other methods may be more efficient for the proposed task than ours. However, to our knowledge, this work is the first one that uses collaborative filtering in visual quality assessment tasks.

There are three files included in this package: PredictPersonalRatings.m is a Matlab implementation of the
scheme. PredictPersonalRatings_Example.m shows a usage example. MOS_example.csv is a data file that contains
an example MOS matrix that can be used for testing.

If you use the implementation in your research, please cite the following publication:

J. Korhonen, "Predicting personal preferences in subjective video quality assessment," *IEEE International Conference on Quality of Multimedia Experience (QoMEX'17)*, Erfurt, Germany, May 2017. [DOI: 10.1109/QoMEX.2017.7965677](https://doi.org/10.1109/QoMEX.2017.7965677)
