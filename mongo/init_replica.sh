#!/bin/bash
mongo --host localhost:27101 <<EOF
    var cfg = { 
        _id: "nodetube", members: [
            {
                _id: 0,
                host: "nodetube-01:27017",
                priority: 2
            },
            {
                _id: 1,
                host: "nodetube-02:27017",
                priority: 1
            },
            {
                _id: 2,
                host: "nodetube-03:27017",
                priority: 1
            }
        ]
    };
    rs.initiate(cfg);
    rs.reconfig(cfg);
    rs.conf();
    rs.status();
    db.getMongo().setReadPref('nearest');
EOF
