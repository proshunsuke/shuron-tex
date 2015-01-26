# 処理のための一般的なメソッド
proc decr { int { n 1 } } {
    if { [ catch {
        uplevel incr $int -$n
    } err ] } {
        return -code error "decr: $err"
    }
    return [ uplevel set $int ]
}

# 配列をコピー
proc copy {ary1 ary2} {
    upvar $ary1 from $ary2 to
    foreach {index value} [array get from *] {
        set to($index) $value
    }
}

# 低い方の帯域幅を返す
proc returnLowBandwidth {bandwidthList node1 node2} {
    upvar $bandwidthList bl
    if { $bl($node1) >= $bl($node2) } {
        return $bl($node2)
    } else {
        return $bl($node1)
    }
}

# ここからシミュレータの処理
# パケットの色設定
proc setPacketColor { ns } {
    $ns color 0 blue
    $ns color 1 red
    $ns color 2 white
}

# ノードの設定
proc setClusterNum {clusterNumArg userNum} {
    upvar $clusterNumArg clusterNum
    if {$userNum == 200} {
        set clusterNum 7
    } elseif {$userNum == 400} {
        set clusterNum 10
    } elseif {$userNum == 600} {
        set clusterNum 14
    } elseif {$userNum == 800} {
        set clusterNum 18
    }
}

proc setNodeNum {digestNodeNum gateNodeNum semiGateNodeNum nomalNodeNum notGetDigestNomalNum getDigestNomalNum userNum clusterNum digestUserRate gateCommentRate semiGateCommentRate gateCommentRate semiGateNodeNum notGetDigestRate} {
    upvar $digestNodeNum dnn $gateNodeNum gnn $semiGateNodeNum sgnn $nomalNodeNum nnn $notGetDigestNomalNum ngdn $getDigestNomalNum gdnn
    set dnn [expr int(ceil([expr $userNum / $clusterNum * $digestUserRate]))]
    set gnn [expr int(ceil([expr $userNum / $clusterNum * $gateCommentRate]))]
    set sgnn [expr int(ceil([expr $userNum / $clusterNum * ($semiGateCommentRate - $gateCommentRate)]))]
    set nnn [expr $userNum / $clusterNum - $dnn - $gnn - $sgnn]
    set ngdn [expr int(ceil([expr $nnn * $notGetDigestRate]))]
    set gdnn [expr $nnn - $ngdn]
}

proc ratioSetting {bandwidthRatio commentRatio clusterNum userNum} {
    upvar $bandwidthRatio br $commentRatio cr
    set basicRatio [expr $userNum/200]
    foreach {index val} [array get br] {
        set tempBandwidthRatio($index) [expr $val*$basicRatio]
    }
    copy tempBandwidthRatio br
    foreach {index val} [array get cr] {
        set tempCommentRatio($index) [expr $val*$basicRatio]
    }
    copy tempCommentRatio cr
}

proc nodeListInit {nodeList nodeListForBandwidth ns userNum} {
    upvar $nodeList nl $nodeListForBandwidth nlfb
    for {set i 0} {$i < $userNum} {incr i} {
        set nl($i) [$ns node]
        set nlfb($i) $nl($i)
    }
}

proc bandwidthListInit {bandwidthList bandwidthRatio nodeListForBandwidth ns userNum} {
    upvar $bandwidthList bl $bandwidthRatio br $nodeListForBandwidth nlfb
    set j 0
    foreach {index val} [array get br] {
        for {set i 0} {$i < $val} {incr i} {
            set bl($nlfb($j)) $index
            incr j
        }
    }
}

proc commentListInit {commentList commentRatio nodeList ns userNum } {
    upvar $commentList cl $commentRatio cr $nodeList nl
    set j 0
    foreach {index val} [array get cr] {
        for {set i 0} {$i < $val} {incr i} {
            set cl($nl($j)) $index
            incr j
        }
    }
}

proc nodeListForBandwidthShuffle {nodeListForBandwidth userNum} {
    upvar $nodeListForBandwidth nlfb
    for {set i 0} {$i < [expr $userNum*5]} {incr i} {
        set temp1 [expr int($userNum*rand())]
        set temp2 [expr int($userNum*rand())]
        set tempNode $nlfb($temp1)
        set nlfb($temp1) $nlfb($temp2)
        set nlfb($temp2) $tempNode
    }
}

proc rootNodeInit {rootNode ns} {
    upvar $rootNode rn
    set rn [$ns node]
    # 配信者ノードの色
    $rn color red
}

proc sortBandwidthList {sortedBandwidthList bandwidthRatio bandwidthList} {
    upvar $sortedBandwidthList sbl $bandwidthRatio br $bandwidthList bl
    # 帯域幅の種類のリスト
    set i 0
    foreach val [lsort -real [array names br]] {
        set kindOfBandwidthList($i) $val
        incr i
    }
    set k 0
    for {set i [expr [array size kindOfBandwidthList]-1]} {$i >= 0} {decr i} {
        foreach {index val} [array get bl] {
            if {$val == $kindOfBandwidthList($i)} {
                set sbl($k) $index
                incr k
            }
        }
    }
}

# Setup Goddard Streaming
# goddardストリーミング生成関数
proc createGoddard { goddard gplayer sfile gCount ns l_node r_node } {
    upvar $goddard gd $gplayer gp $sfile sf $gCount gc
    set gs($gc) [new GoddardStreaming $ns $l_node $r_node UDP 1000 $gc]
    set gd($gc) [$gs($gc) getobject goddard]
    set gp($gc) [$gs($gc) getobject gplayer]
    $gp($gc) set upscale_interval_ 30.0
    set sf($gc) [open stream-udp.tr w]
    $gp($gc) attach $sf($gc)
    incr gc
    return
}

# create goddard
proc createNomalNodeStream {nomalDigestNode nomalNotDigestNode digestNode goddard gplayer sfile gCount rootNode ns clusterNum getDigestNomalNum notGetDigestNomalNum digestNodeNum} {
    upvar $nomalDigestNode ndn $nomalNotDigestNode nndn $digestNode dn $goddard gd $gplayer gp $sfile sf $gCount gc
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $getDigestNomalNum} {incr j} {
            createGoddard gd gp sf gc $ns $rootNode $ndn($i,$j)
        }
        for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
            createGoddard gd gp sf gc $ns $rootNode $nndn($i,$j)
        }
        for {set j 0} {$j < $digestNodeNum} {incr j} {
            createGoddard gd gp sf gc $ns $rootNode $dn($i,$j)
        }
    }
}