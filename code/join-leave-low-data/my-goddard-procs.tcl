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

proc setNodeNum {digestNodeNum gateNodeNum semiGateNodeNum nomalNodeNum notGetDigestNomalNum getDigestNomalNum joinNodeNum userNum clusterNum digestUserRate gateCommentRate semiGateCommentRate gateCommentRate semiGateNodeNum notGetDigestRate finishTime} {
    upvar $digestNodeNum dnn $gateNodeNum gnn $semiGateNodeNum sgnn $nomalNodeNum nnn $notGetDigestNomalNum ngdn $getDigestNomalNum gdnn $joinNodeNum jnn
    set dnn [expr int(ceil([expr $userNum / $clusterNum * $digestUserRate]))]
    set gnn [expr int(ceil([expr $userNum / $clusterNum * $gateCommentRate]))]
    set sgnn [expr int(ceil([expr $userNum / $clusterNum * ($semiGateCommentRate - $gateCommentRate)]))]
    set nnn [expr $userNum / $clusterNum - $dnn - $gnn - $sgnn]
    set ngdn [expr int(ceil([expr $nnn * $notGetDigestRate]))]
    set gdnn [expr $nnn - $ngdn]
    set jnn [expr $finishTime / 10]
}

proc ratioSetting {bandwidthRatio commentRatio clusterNum userNum} {
    upvar $bandwidthRatio br $commentRatio cr

    set basicRatio [expr $userNum/$userNum]
    foreach {index val} [array get br] {
        set tempBandwidthRatio($index) [expr $val*$basicRatio]
    }
    copy tempBandwidthRatio br

    foreach {index val} [array get cr] {
        set tempCommentRatio($index) [expr $val*$basicRatio]
    }
    copy tempCommentRatio cr
}

proc nodeListInit {nodeList nodeListForBandwidth joinNodeList replaceGateNodeList replaceSemiGateNodeList replaceDigestNodeList ns userNum finishTime clusterNum digestNodeNum gateNodeNum semiGateNodeNum joinLeaveInterval} {
    upvar $nodeList nl $nodeListForBandwidth nlfb $joinNodeList jnl $replaceGateNodeList rgnl $replaceSemiGateNodeList rsgnl $replaceDigestNodeList rdnl

    # 既存ノード
    for {set i 0} {$i < $userNum} {incr i} {
        set nl($i) [$ns node]
        set nlfb($i) $nl($i)
    }


    # 新規参加ノード
    for {set i 0} {$i < [expr $finishTime * $clusterNum / $joinLeaveInterval]} {incr i} {
        set jnl($i) [$ns node]
    }

    # 代わりのノード
    # ゲートノード
    for {set i 0} {$i < [expr $gateNodeNum*$clusterNum]} {incr i} {
        set rgnl($i) [$ns node]
    }

    # セミゲートノード
    for {set i 0} {$i < [expr $semiGateNodeNum*$clusterNum]} {incr i} {
        set rsgnl($i) [$ns node]
    }

    # ダイジェストノード
    for {set i 0} {$i < [expr $digestNodeNum*$clusterNum]} {incr i} {
        set rdnl($i) [$ns node]
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

proc createUDP {udp cbr sfile udpCount ns l_node r_node group} {
    upvar $udp u $cbr c $sfile sf $udpCount uc
    set u($uc) [new Agent/UDP]
    set sf($uc) [open stream-udp.tr w]
    $u($uc) attach $sf($uc)
    $ns attach-agent $l_node $u($uc)
    $u($uc) set dst_addr_ $group
    $u($uc) set dst_port_ 0
    set c($uc) [new Application/Traffic/CBR]
    $c($uc) attach-agent $u($uc)

    incr uc
}

proc createNomalNodeUDPStream {nomalDigestNode nomalNotDigestNode digestNode udp cbr sfile udpCount joinNodeList rootNode ns clusterNum getDigestNomalNum notGetDigestNomalNum digestNodeNum group} {
    upvar $nomalDigestNode ndn $nomalNotDigestNode nndn $digestNode dn $udp u $cbr c $sfile sf $udpCount uc $joinNodeList jnl
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $getDigestNomalNum} {incr j} {
            createUDP u c sf uc $ns $rootNode $ndn($i,$j) $group
        }
        for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
            createUDP u c sf uc $ns $rootNode $nndn($i,$j) $group
        }
        for {set j 0} {$j < $digestNodeNum} {incr j} {
            createUDP u c sf uc $ns $rootNode $dn($i,$j) $group
        }
    }
}
