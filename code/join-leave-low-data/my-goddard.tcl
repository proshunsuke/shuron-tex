#NS simulator object
set ns [new Simulator -multicast on]

# デフォルトの値はここで定義
source my-goddard-default.tcl

# 共通の関数はここで定義
source my-goddard-procs.tcl

# 入力値(ユーザ数は必ず200の倍数)
set userNum 28

# ユーザ数に応じて変化
set clusterNum 0

# 実験用パラメータ
set digestUserRate 0.2
set gateBandWidthRate 0.3
set gateCommentRate 0.1
set semiGateBandWidthRate 0.3
set semiGateCommentRate 0.2
set notGetDigestRate 0.2
set connectNomalNodeRate 0.25

# ノード
set rootNode ""
set gateNode(0,0) ""
set semiGateNode(0,0) ""
set digestNode(0,0) ""
set nomalDigestNode(0,0) ""
set nomalNotDigestNode(0,0) ""
set joinNode(0,0) ""
set replaceGateNode(0,0) ""
set replaceSemiGateNode(0,0) ""
set replaceDigestNode(0,0) ""

# ノードの数
set digestNodeNum 0
set gateNodeNum 0
set semiGateNodeNum 0
set nomalNodeNum  0
set notGetDigestNomalNum 0
set getDigestNomalNum 0
set joinNodeNum 0
set replaceGateNodeNum 0
set replaceSemiGateNodeNum 0
set replaceDigestNodeNum 0

# ノードリスト
set nodeList(0) ""
set nodeListForBandwidth(0) ""
set joinNodeList(0) ""
set replaceGateNodeList(0) ""
set replaceSemiGateNodeList(0) ""
set replaceDigestNodeList(0) ""

# 各ノードの種類のリスト
# {node1: "digest", node2: "gate"...}
set gateNodeTypeList(0) ""
set semiGateNodeTypeList(0) ""
set digestNodeTypeList(0) ""

# 各ノードと代わりのノードリスト
# {node1: replaceNode1, node2: replaceNode2...}
set gateToReplaceList(0) ""
set semiGateToReplaceList(0) ""
set digestToReplaceList(0) ""

# ゲートノードとセミゲートノードのノードリスト
# {node1: replaceNode1, node2: replaceNode2...}
set gateToSemiGateList(0) ""

# 帯域幅ノードリスト(Mbps)
set bandwidthList(0) ""

# 一時退避帯域幅ノードリスト
set temporalBandwidthList(0) ""

# コメント数ノードリスト
set commentList(0) ""

# ダイジェスト以外のソートされた帯域幅ノードリスト
set sortedBandwidthList(0) ""

# goddardのための変数宣言
set goddard(0) ""
set gplayer(0) ""
# set sfile(0) ""
set gCount 0

# グループ
set mproto ""
set mrthandlee ""
set group ""
set udp ""
set cbr ""
set sfile ""
set startTime 0.0
set joinLeaveInterval 10.0

# my-goddardのための関数

# この中で便宜上一時的に帯域幅リストからノードを削除している
proc digestNodeInit {digestNode digestNodeTypeList bandwidthList temporalBandwidthList nodeListForBandwidth nodeList userNum clusterNum digestNodeNum} {
    upvar $digestNode dn $digestNodeTypeList dntl $bandwidthList bl $temporalBandwidthList tbl $nodeListForBandwidth nlfb $nodeList nl

    copy bl tbl

    set commentI [expr $userNum-1]
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $digestNodeNum} {incr j} {
            set dn($i,$j) $nl($commentI)
            set dntl($nl($commentI)) "digestNode"

            # 帯域幅リストからダイジェストノードを削除
            array unset bl $nl($commentI)

            # 帯域幅ノードリストからダイジェストノードを削除
            for {set k 0} {$k < [array size nlfb]} {incr k} {
                if {[array get nlfb $k] == []} {
                    continue
                }
                if {$nlfb($k) == $nl($commentI)} {
                    array unset nlfb $k
                    break
                }
            }

            # ダイジェストノードの色
            $dn($i,$j) color yellow

            decr commentI
        }
    }
    return
}

proc gateNodeInit {gateNode gateNodeTypeList sortedBandwidthList clusterNum gateNodeNum} {
    upvar $gateNode gn $gateNodeTypeList gntl $sortedBandwidthList sbl
    set k 0
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $gateNodeNum} {incr j} {
            set gn($i,$j) $sbl($k)
            set gntl($sbl($k)) "gateNode"

            # ゲートノードの色
            $gn($i,$j) color #006400

            incr k
        }
    }
    return
}

proc semiGateNodeInit {semiGateNode semiGateNodeTypeList gateToSemiGateList sortedBandwidthList gateNode clusterNum semiGateNodeNum} {
    upvar $semiGateNode sgn $semiGateNodeTypeList sgntl $gateToSemiGateList gtsgl $sortedBandwidthList sbl $gateNode gn
    set k [array size gn]
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $semiGateNodeNum} {incr j} {
            set sgn($i,$j) $sbl($k)
            set sgntl($sbl($k)) "semiGateNode"
            set gtsgl($gn($i,$j)) $sgn($i,$j)

            # セミゲートノードの色
            $sgn($i,$j) color #00ff00

            incr k
        }
    }

    return
}

proc nomalNodeInit {nomalNotDigestNode nomalDigestNode gateNode semiGateNode sortedBandwidthList clusterNum notGetDigestNomalNum getDigestNomalNum} {
    upvar $nomalNotDigestNode nndn $nomalDigestNode ndn $gateNode gn $semiGateNode sgn $sortedBandwidthList sbl

    set k [expr [array size gn] + [array size sgn]]
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
            set nndn($i,$j) $sbl($k)

            # ダイジェスト未取得ノーマルノードの色
            $nndn($i,$j) color pink

            incr k
        }
    }

    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $getDigestNomalNum} {incr j} {
            set ndn($i,$j) $sbl($k)

            # ダイジェスト取得ノーマルノードの色
            $ndn($i,$j) color orange

            incr k
        }
    }

    # 残りのノードは全てダイジェスト取得済みノーマルノードへ
    set limit [expr [array size sbl]-$k]

    for {set i 0} {$i < $limit} {incr i} {
        set ndn($i,$getDigestNomalNum) $sbl($k)

        # ダイジェスト取得ノーマルノードの色
        $ndn($i,$getDigestNomalNum) color orange

        incr k
    }
    return
}

proc joinNodeInit {joinNode joinNodeList bandwidthRatio clusterNum finishTime} {
    upvar $joinNode jn $joinNodeList jnl

    set k 0
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < [expr ($finishTime / 10)]} {incr j} {
            set jn($i,$j) $jnl($k)

            # 新規参加ノードの色
            $jn($i,$j) color #800080

            incr k
        }
    }
}

proc replaceGateNodeInit {gateNode gateToReplaceList replaceGateNode replaceGateNodeList clusterNum gateNodeNum} {
    upvar $gateNode gn $gateToReplaceList gtrl $replaceGateNode rgn $replaceGateNodeList rgnl
    set k 0
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $gateNodeNum} {incr j} {
            set rgn($i,$j) $rgnl($k)
            set gtrl($gn($i,$j)) $rgn($i,$j)

            # 代わりのゲートノードの色
            $rgn($i,$j) color #0000ff

            incr k
        }
    }
}

proc replaceSemiGateNodeInit {semiGateNode semiGateToReplaceList replaceSemiGateNode replaceSemiGateNodeList clusterNum semiGateNodeNum} {
    upvar $semiGateNode sgn $semiGateToReplaceList sgtrl $replaceSemiGateNode rsgn $replaceSemiGateNodeList rsgnl
    set k 0
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $semiGateNodeNum} {incr j} {
            set rsgn($i,$j) $rsgnl($k)
            set sgtrl($sgn($i,$j)) $rsgn($i,$j)

            # 代わりのセミゲートノードの色
            $rsgn($i,$j) color #4169e1

            incr k
        }
    }
}

proc replaceDigestNodeInit {digestNode digestToReplaceList replaceDigestNode replaceDigestNodeList clusterNum digestNodeNum} {
    upvar $digestNode dn $digestToReplaceList dtrl $replaceDigestNode rdn $replaceDigestNodeList rdnl
    set k 0
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $digestNodeNum} {incr j} {
            set rdn($i,$j) $rdnl($k)
            set dtrl($dn($i,$j)) $rdn($i,$j)

            # 代わりのダイジェストノードの色
            $rdn($i,$j) color #00bfff

            incr k
        }
    }
}


# ノード間の接続
# 常に低いノード側の帯域幅で接続

# 帯域幅の設定する必要あり
proc connectGateNodeInCluster {gateNode semiGateNode replaceGateNode bandwidthList rootNode ns gateNodeNum clusterNum selfClusterNum} {
    upvar $gateNode gn $semiGateNode sgn $replaceGateNode rgn $bandwidthList bl
    # 配信者ノード
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        $ns duplex-link $gn($selfClusterNum,$i) $rootNode $bl($gn($selfClusterNum,$i))Mb 500ms DropTail
    }

    # ゲートノード同士：１→２　２→３　３→１
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        if { [expr $i+1] >= $gateNodeNum } {
            set bandwidth [returnLowBandwidth bl $gn($selfClusterNum,$i) $gn($selfClusterNum,[expr $i+1-$gateNodeNum])]
            $ns duplex-link $gn($selfClusterNum,$i) $gn($selfClusterNum,[expr $i+1-$gateNodeNum]) [expr $bandwidth]Mb 100ms DropTail
        } else {
            set bandwidth [returnLowBandwidth bl $gn($selfClusterNum,$i) $gn($selfClusterNum,[expr $i+1])]
            $ns duplex-link $gn($selfClusterNum,$i) $gn($selfClusterNum,[expr $i+1]) [expr $bandwidth]Mb 100ms DropTail
        }
    }

    # ゲートノードとセミゲートノード
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        set bandwidth [returnLowBandwidth bl $gn($selfClusterNum,$i) $sgn($selfClusterNum,$i)]
        $ns duplex-link $gn($selfClusterNum,$i) $sgn($selfClusterNum,$i) [expr $bandwidth]Mb 100ms DropTail

        # 代わりのゲートノードの帯域幅設定
        set bl($rgn($selfClusterNum,$i)) $bl($sgn($selfClusterNum,$i))
    }
}

proc connectGateNodeOutside {gateNode bandwidthList nsArg clusterNum gateNodeNum selfIndexNum} {
    upvar $gateNode gn $bandwidthList bl $nsArg ns
    # クラスタ外のゲートノード同士：１→２ ２→３... 7→１
    for {set i 0} {$i < $clusterNum} {incr i} {
        if { [expr $i+1] >= $clusterNum } {
            set bandwidth [returnLowBandwidth bl $gn($i,$selfIndexNum) $gn([expr $i+1-$clusterNum],$selfIndexNum)]
            $ns duplex-link $gn($i,$selfIndexNum) $gn([expr $i+1-$clusterNum],$selfIndexNum) [expr $bandwidth]Mb 100ms DropTail
        } else {
            set bandwidth [returnLowBandwidth bl $gn($i,$selfIndexNum) $gn([expr $i+1],$selfIndexNum)]
            $ns duplex-link $gn($i,$selfIndexNum) $gn([expr $i+1],$selfIndexNum) [expr $bandwidth]Mb 100ms DropTail
        }
    }
}

proc connectSemiGateNode {semiGateNode digestNode nomalDigestNode nomalNotDigestNode bandwidthList ns clusterNum semiGateNodeNum notGetDigestNomalNum getDigestNomalNum selfIndexNum } {
    upvar $semiGateNode sgn $digestNode dn $nomalDigestNode ndn $nomalNotDigestNode nndn $bandwidthList bl
    # ダイジェストノード
    for {set i 0} {$i < $semiGateNodeNum}  {incr i} {
        if {[array get dn $selfIndexNum,[expr $i*2]] == []} {
                    continue
        }
        set bandwidth [returnLowBandwidth bl $sgn($selfIndexNum,$i) $dn($selfIndexNum,[expr $i*2])]
        $ns duplex-link $sgn($selfIndexNum,$i) $dn($selfIndexNum,[expr $i*2]) [expr $bandwidth]Mb 100ms DropTail
        if {[array get dn $selfIndexNum,[expr $i*2+1]] == []} {
                    continue
        }
        set bandwidth [returnLowBandwidth bl $sgn($selfIndexNum,$i) $dn($selfIndexNum,[expr $i*2+1])]
        $ns duplex-link $sgn($selfIndexNum,$i) $dn($selfIndexNum,[expr $i*2+1]) [expr $bandwidth]Mb 100ms DropTail
    }

    # ノーマルノード
    for {set i 0} {$i < $semiGateNodeNum}  {incr i} {
        set digestBorderNum [expr int(($notGetDigestNomalNum+$getDigestNomalNum)*rand())]
        if {$digestBorderNum >= $notGetDigestNomalNum} {
            set bandwidth [returnLowBandwidth bl $sgn($selfIndexNum,$i) $ndn($selfIndexNum,[expr $digestBorderNum-$notGetDigestNomalNum])]
            $ns duplex-link $sgn($selfIndexNum,$i) $ndn($selfIndexNum,[expr $digestBorderNum-$notGetDigestNomalNum]) [expr $bandwidth]Mb 100ms DropTail
        } else {
            set bandwidth [returnLowBandwidth bl $sgn($selfIndexNum,$i) $nndn($selfIndexNum,$digestBorderNum)]
            $ns duplex-link $sgn($selfIndexNum,$i) $nndn($selfIndexNum,$digestBorderNum) [expr $bandwidth]Mb 100ms DropTail
        }
    }
}

proc connectDigestNode {digestNode nomalNotDigestNode bandwidthList ns notGetDigestNomalNum getDigestNomalNum digestNodeNum selfIndexNum } {
    upvar $digestNode dn $nomalNotDigestNode nndn $bandwidthList bl
    # ダイジェスト未取得ノーマルノード
    for {set i 0} {$i < $digestNodeNum}  {incr i} {
        for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
            set bandwidth [returnLowBandwidth bl $dn($selfIndexNum,$i) $nndn($selfIndexNum,$j)]
            $ns duplex-link $dn($selfIndexNum,$i) $nndn($selfIndexNum,$j) [expr $bandwidth]Mb 100ms DropTail
        }
    }
}

proc connectNomalNode {nomalDigestNode nomalNotDigestNode bandwidthList ns clusterNum connectNomalNodeRate notGetDigestNomalNum getDigestNomalNum nomalNodeNum selfIndexNum } {
    upvar $nomalDigestNode ndn $nomalNotDigestNode nndn $bandwidthList bl

    # とりあえずリストに全部入れる
    for {set i 0} {$i < [expr $nomalNodeNum+1]} {incr i} {
        if {$i >= $notGetDigestNomalNum} {
            if {[array get ndn $selfIndexNum,[expr $i-$notGetDigestNomalNum]] == []} { continue }
            set nomalNodeList($i) $ndn($selfIndexNum,[expr $i-$notGetDigestNomalNum])
        } else {
            set nomalNodeList($i) $nndn($selfIndexNum,$i)
        }
    }

    # 適当な回数リストの中身をシャッフル
    set temp ""
    for {set i 0} {$i < 100 } {incr i} {
        set randomNum1 [expr int(($nomalNodeNum)*rand())]
        set randomNum2 [expr int(($nomalNodeNum)*rand())]
        set temp $nomalNodeList($randomNum1)
        set $nomalNodeList($randomNum1) $nomalNodeList($randomNum2)
        set $nomalNodeList($randomNum2) $temp
    }

    set connectNomalNum [expr int(ceil($nomalNodeNum*$connectNomalNodeRate))]

    # ノーマルノード同士：０→１　０→２　０→３　０→４、１→２　１→３...１４→１５　１４→０　１４→１　１４→２
    for {set i 0} {$i < [expr $nomalNodeNum+1]} {incr i} {
        for {set j 0} {$j < $connectNomalNum} {incr j} {
            if { [expr $i+$j+1] >= $nomalNodeNum } {
                if {[array get nomalNodeList $i] == []} { continue }
                set bandwidth [returnLowBandwidth bl $nomalNodeList($i) $nomalNodeList([expr $i+$j+1-$nomalNodeNum])]
                $ns duplex-link $nomalNodeList($i) $nomalNodeList([expr $i+$j+1-$nomalNodeNum]) [expr $bandwidth]Mb 100ms DropTail
            } else {
                set bandwidth [returnLowBandwidth bl $nomalNodeList($i) $nomalNodeList([expr $i+$j+1])]
                $ns duplex-link $nomalNodeList($i) $nomalNodeList([expr $i+$j+1]) [expr $bandwidth]Mb 100ms DropTail
            }
        }
    }
}

proc connectJoinNode {joinNode nomalDigestNode nomalNotDigestNode bandwidthList ns clusterNum joinNodeNum nomalNodeNum selfIndexNum} {
    upvar $joinNode jn $nomalDigestNode ndn $nomalNotDigestNode nndn $bandwidthList bl
    # joinNodeとnomalDigestNode
    set i 0
    while {[array get ndn $selfIndexNum,$i] != []} {
        if {[array get jn $selfIndexNum,$i] == []} {
            break
        }
        $ns duplex-link $jn($selfIndexNum,$i) $ndn($selfIndexNum,$i) $bl($ndn($selfIndexNum,$i))Mb 100ms DropTail
        incr i
    }
    # joinNodeとnomalNotDigestNode
    set j 0
    while {[array get nndn $selfIndexNum,$j] != [] && [array get jn $selfIndexNum,$i] != []} {
        $ns duplex-link $jn($selfIndexNum,$i) $nndn($selfIndexNum,$j) $bl($ndn($selfIndexNum,$j))Mb 100ms DropTail
        incr i
    }

    set connectJoinNum 4
    for {set i 0 } {$i < [expr $joinNodeNum - 1]} {incr i} {
        set jList($i) $jn($selfIndexNum,$i)
    }

    # joinNode同士
    for {set i 0} {$i < [expr $joinNodeNum-2]} {incr i} {
        for {set j 0} {$j < $connectJoinNum} {incr j} {
            if { [expr $i+$j+1] >= $joinNodeNum } {
                if {[array get jList $i] == []} { continue }
                $ns duplex-link $jList($i) $jList([expr int($i+$j+1-$joinNodeNum)]) 1.0Mb 100ms DropTail
            } else {
                if {$jList($i) == $jList([expr $i+$j])} {
                    $ns duplex-link $jList($i) $jList([expr $i+$j+1]) 1.0Mb 100ms DropTail
                } else {
                    $ns duplex-link $jList($i) $jList([expr $i+$j]) 1.0Mb 100ms DropTail
                }
            }
        }
    }
}

# 代わりのゲートノード
proc connectReplaceGateNodeInCluster {gateNode semiGateNode replaceGateNode bandwidthList rootNode ns gateNodeNum clusterNum selfClusterNum} {
    upvar $gateNode gn $semiGateNode sgn $replaceGateNode rgn $bandwidthList bl
    # 配信者ノード
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        $ns duplex-link $rgn($selfClusterNum,$i) $rootNode $bl($rgn($selfClusterNum,$i))Mb 500ms DropTail
    }

    # ゲートノード同士：１→２　２→３　３→１
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        if { [expr $i+1] >= $gateNodeNum } {
            set bandwidth [returnLowBandwidth bl $rgn($selfClusterNum,$i) $gn($selfClusterNum,[expr $i+1-$gateNodeNum])]
            $ns duplex-link $rgn($selfClusterNum,$i) $gn($selfClusterNum,[expr $i+1-$gateNodeNum]) [expr $bandwidth]Mb 100ms DropTail
        } else {
            set bandwidth [returnLowBandwidth bl $rgn($selfClusterNum,$i) $gn($selfClusterNum,[expr $i+1])]
            $ns duplex-link $rgn($selfClusterNum,$i) $gn($selfClusterNum,[expr $i+1]) [expr $bandwidth]Mb 100ms DropTail
        }
    }

    # ゲートノードとセミゲートノード
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        set bandwidth [returnLowBandwidth bl $rgn($selfClusterNum,$i) $sgn($selfClusterNum,$i)]
        $ns duplex-link $rgn($selfClusterNum,$i) $sgn($selfClusterNum,$i) [expr $bandwidth]Mb 100ms DropTail
    }
}

# 代わりのゲートノード
proc connectReplaceGateNodeOutside {gateNode replaceGateNode bandwidthList nsArg clusterNum gateNodeNum selfIndexNum} {
    upvar $gateNode gn $replaceGateNode rgn $bandwidthList bl $nsArg ns
    # クラスタ外のゲートノード同士：１→２ ２→３... 7→１
    for {set i 0} {$i < $clusterNum} {incr i} {
        if { [expr $i+1] >= $clusterNum } {
            set bandwidth [returnLowBandwidth bl $rgn($i,$selfIndexNum) $gn([expr $i+1-$clusterNum],$selfIndexNum)]
            $ns duplex-link $rgn($i,$selfIndexNum) $gn([expr $i+1-$clusterNum],$selfIndexNum) [expr $bandwidth]Mb 100ms DropTail
        } else {
            set bandwidth [returnLowBandwidth bl $rgn($i,$selfIndexNum) $gn([expr $i+1],$selfIndexNum)]
            $ns duplex-link $rgn($i,$selfIndexNum) $gn([expr $i+1],$selfIndexNum) [expr $bandwidth]Mb 100ms DropTail
        }
    }
}

# 代わりのセミゲートノード
proc replaceSemiGateNodeBandwitdhSetting {nomalDigestNode replaceSemiGateNode sortedBandwidthList bandwidthList clusterNum} {
    upvar $nomalDigestNode ndn $replaceSemiGateNode rsgn $sortedBandwidthList sbl $bandwidthList bl

    for {set i 0} {$i < $clusterNum} {incr i} {
        set rsgnI 0
        for {set j 0} {$j < [expr [array size sbl] - 1]} {incr j} {
            set k 0
            while { [array get ndn $i,$k] != []} {
                if {[array get rsgn $i,$rsgnI] == []} { break }
                if {$ndn($i,$k) == $sbl($j)} {
                    set bl($rsgn($i,$rsgnI)) $ndn($i,$k)
                    incr rsgnI
                }
                incr k
            }
        }
    }
}

proc connectReplaceSemiGateNode {semiGateNode digestNode nomalDigestNode nomalNotDigestNode replaceSemiGateNode bandwidthList ns clusterNum semiGateNodeNum notGetDigestNomalNum getDigestNomalNum selfIndexNum } {
    upvar $semiGateNode sgn $digestNode dn $nomalDigestNode ndn $nomalNotDigestNode nndn $bandwidthList bl $replaceSemiGateNode rsgn
    # ダイジェストノード
    for {set i 0} {$i < $semiGateNodeNum}  {incr i} {
        if {[array get dn $selfIndexNum,[expr $i*2]] == []} {
                    continue
        }
        set bandwidth [returnLowBandwidth bl $rsgn($selfIndexNum,$i) $dn($selfIndexNum,[expr $i*2])]
        $ns duplex-link $rsgn($selfIndexNum,$i) $dn($selfIndexNum,[expr $i*2]) [expr $bandwidth]Mb 100ms DropTail
        if {[array get dn $selfIndexNum,[expr $i*2+1]] == []} {
                    continue
        }
        set bandwidth [returnLowBandwidth bl $rsgn($selfIndexNum,$i) $dn($selfIndexNum,[expr $i*2+1])]
        $ns duplex-link $rsgn($selfIndexNum,$i) $dn($selfIndexNum,[expr $i*2+1]) [expr $bandwidth]Mb 100ms DropTail
    }

    # ノーマルノード
    for {set i 0} {$i < $semiGateNodeNum}  {incr i} {
        set digestBorderNum [expr int(($notGetDigestNomalNum+$getDigestNomalNum)*rand())]
        if {$digestBorderNum >= $notGetDigestNomalNum} {
            set bandwidth [returnLowBandwidth bl $rsgn($selfIndexNum,$i) $ndn($selfIndexNum,[expr $digestBorderNum-$notGetDigestNomalNum])]
            $ns duplex-link $rsgn($selfIndexNum,$i) $ndn($selfIndexNum,[expr $digestBorderNum-$notGetDigestNomalNum]) [expr $bandwidth]Mb 100ms DropTail
        } else {
            set bandwidth [returnLowBandwidth bl $rsgn($selfIndexNum,$i) $nndn($selfIndexNum,$digestBorderNum)]
            $ns duplex-link $rsgn($selfIndexNum,$i) $nndn($selfIndexNum,$digestBorderNum) [expr $bandwidth]Mb 100ms DropTail
        }
    }
}

# 代わりのダイジェストノード
proc replaceDigestNodeBandwitdhSetting {nomalDigestNode replaceDigestNode commentList bandwidthList clusterNum} {
    upvar $nomalDigestNode ndn $replaceDigestNode rdn $commentList cl $bandwidthList bl
    set i 0
    set num [expr [array size cl] - 1]
    foreach {index val} [array get cl] {
        set tcl($num) $index
        decr num
    }

    for {set i 0} {$i < $clusterNum} {incr i} {
        set rdnI 0
        for {set j 0} {$j < [expr [array size tcl] - 1]} {incr j} {
            set k 0
            while { [array get ndn $i,$k] != []} {
                if {[array get rdn $i,$rdnI] == []} { break }
                if {$ndn($i,$k) == $tcl($j)} {
                    set bl($rdn($i,$rdnI)) $ndn($i,$k)
                    incr rdnI
                }
                incr k
            }
        }
    }
}

proc connectReplaceDigestNode {digestNode nomalNotDigestNode replaceDigestNode bandwidthList ns notGetDigestNomalNum getDigestNomalNum digestNodeNum selfIndexNum } {
    upvar $digestNode dn $nomalNotDigestNode nndn $bandwidthList bl $replaceDigestNode rdn
    # ダイジェスト未取得ノーマルノード
    for {set i 0} {$i < $digestNodeNum}  {incr i} {
        for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
            set bandwidth [returnLowBandwidth bl $rdn($selfIndexNum,$i) $nndn($selfIndexNum,$j)]
            $ns duplex-link $rdn($selfIndexNum,$i) $nndn($selfIndexNum,$j) [expr $bandwidth]Mb 100ms DropTail
        }
    }
}

proc UDPStreamInit {mproto mrthandle group udp cbr rcvr sfile ns rootNode } {
    upvar $mproto mp $mrthandle mh $group g $udp u $cbr c $rcvr r $sfile sf
    set mp DM
    set mh [$ns mrtproto $mp {}]
    set g [Node allocaddr]
    set u [new Agent/UDP]
    $u set dst_addr_ $g
    $u set dst_port_ 0
    $u set class_ 1

    set sf [open stream-udp.tr w]
    $ns attach-agent $rootNode $u
    set c [new Application/Traffic/CBR]
    $c attach-agent $u

    set r [new Agent/LossMonitor]
}

proc attachInit {nodeList joinNodeList replaceGateNodeList replaceSemiGateNodeList replaceDigestNodeList startTime ns rcvr group} {
    upvar $nodeList nl $joinNodeList jnl $replaceGateNodeList rgnl $replaceSemiGateNodeList rsgnl $replaceDigestNodeList rdnl $startTime st
    set st 0.0
    for {set i 0} {$i < [expr [array size nl] - 1]} {incr i} {
        $ns attach-agent $nl($i) $rcvr
        $ns at $st "$nl($i) join-group $rcvr $group"
        set st [expr $st + 0.01]
    }

    for {set i 0} {$i < [expr [array size rgnl] - 1]} {incr i} {
        $ns attach-agent $rgnl($i) $rcvr
        $ns at $st "$rgnl($i) join-group $rcvr $group"
        set st [expr $st + 0.01]
        $ns at $st "$rgnl($i) leave-group $rcvr $group"
        set st [expr $st + 0.01]
    }

    for {set i 0} {$i < [expr [array size rsgnl] - 1]} {incr i} {
        $ns attach-agent $rsgnl($i) $rcvr
        $ns at $st "$rsgnl($i) join-group $rcvr $group"
        set st [expr $st + 0.01]
        $ns at $st "$rsgnl($i) leave-group $rcvr $group"
        set st [expr $st + 0.01]
    }

    for {set i 0} {$i < [expr [array size rdnl] - 1]} {incr i} {
        $ns attach-agent $rdnl($i) $rcvr
        $ns at $st "$rdnl($i) join-group $rcvr $group"
        set st [expr $st + 0.01]
        $ns at $st "$rdnl($i) leave-group $rcvr $group"
        set st [expr $st + 0.01]
    }
}

# 参加時はn規定の時刻+0.01の時
proc newJoin {joinNodeList ns rcvr group startTime finishTime joinLeaveInterval} {
    upvar $joinNodeList jnl
    set joinTime [expr $startTime + 0.01]
    copy jnl nl
    set num [expr [array size jnl] - 1]
    for {set i 0} {$i < [expr $num*5]} {incr i} {
        set temp1 [expr int($num*rand())]
        set temp2 [expr int($num*rand())]
        set tempNode $nl($temp1)
        set nl($temp1) $nl($temp2)
        set nl($temp2) $tempNode
    }
    set k 0
    while {$joinTime < $finishTime} {
        $ns at $joinTime "$nl($k) join-group $rcvr $group"
        set joinTime [expr $joinTime + $joinLeaveInterval]
        incr k
    }
}

# 離脱時はn規定の時刻+0.02の時
# 続けて代わりのノードが参加する時は+0.03の時
proc leaveNode {nodeList joinNodeList replaceGateNodeList replaceSemiGateNodeList replaceDigestNodeList gateNodeTypeList semiGateNodeTypeList digestNodeTypeList gateToReplaceList semiGateToReplaceList digestToReplaceList gateToSemiGateList commentList startTime finishTime joinLeaveInterval ns rcvr group} {
    upvar $nodeList nl $joinNodeList jnl $replaceGateNodeList rgnl $replaceSemiGateNodeList rsgnl $replaceDigestNodeList rdnl $gateNodeTypeList gntl $semiGateNodeTypeList sgntl $digestNodeTypeList dntl $gateToReplaceList gtrl $semiGateToReplaceList sgtrl $digestToReplaceList dtrl $gateToSemiGateList gtsgl $commentList cl
    set num [expr [array size nl] - 1]
    copy nl tnl

    copy cl tcl

    set selectNum 0
    set num [expr [array size tnl]]
    set loopNum [expr $finishTime / $joinLeaveInterval]
    while {$selectNum < $loopNum} {
        set rand1 [expr int(($num - 1)*rand())]
        if {[array get tnl $rand1] == []} {
            continue
        }

        if {[array get tcl $tnl($rand1)] == []} {
            continue
        }

        set border [expr 1000*rand()]
        if {$tcl($tnl($rand1)) == 25} {
            if {$border > 990} {
                set list($selectNum) $tnl($rand1)
                array unset tnl $rand1
                incr selectNum
            }
        } elseif {$tcl($tnl($rand1)) == 22} {
            if {$border > 960} {
                set list($selectNum) $tnl($rand1)
                array unset tnl $rand1
                incr selectNum
            }
        } elseif {$tcl($tnl($rand1)) == 20} {
            if {$border > 930} {
                set list($selectNum) $tnl($rand1)
                array unset tnl $rand1
                incr selectNum
            }
        } elseif {$tcl($tnl($rand1)) == 17} {
            if {$border > 900} {
                set list($selectNum) $tnl($rand1)
                array unset tnl $rand1
                incr selectNum
            }
        } elseif {$tcl($tnl($rand1)) == 15} {
            if {$border > 800} {
                set list($selectNum) $tnl($rand1)
                array unset tnl $rand1
                incr selectNum
            }
        } elseif {$tcl($tnl($rand1)) == 12} {
            if {$border > 500} {
                set list($selectNum) $tnl($rand1)
                array unset tnl $rand1
                incr selectNum
            }
        } elseif {$tcl($tnl($rand1)) == 10} {
            if {$border > 400} {
                set list($selectNum) $tnl($rand1)
                array unset tnl $rand1
                incr selectNum
            }
        } elseif {$tcl($tnl($rand1)) == 7} {
            if {$border > 300} {
                set list($selectNum) $tnl($rand1)
                array unset tnl $rand1
                incr selectNum
            }
        } elseif {$tcl($tnl($rand1)) == 5} {
            if {$border > 100} {
                set list($selectNum) $tnl($rand1)
                array unset tnl $rand1
                incr selectNum
            }
        } elseif {$tcl($tnl($rand1)) == 2} {
            if {$border > 300} {
                set list($selectNum) $tnl($rand1)
                array unset tnl $rand1
                incr selectNum
            }
        }
    }

    set k 0
    set leaveTime [expr $startTime + 0.02]
    while {$leaveTime < $finishTime} {
        # digestNodeだったら
        if {[array get dntl $list($k)] != []} {
            if {$dntl($list($k)) == "digestNode"} {
                $ns at $leaveTime "$list($k) leave-group $rcvr $group"
                $ns at [expr $leaveTime + 0.01] "$dtrl($list($k)) join-group $rcvr $group"
            }
        }

        if {[array get sgntl $list($k)] != []} {
            if {$sgntl($list($k)) == "semiGateNode"} {
                $ns at $leaveTime "$list($k) leave-group $rcvr $group"
                $ns at [expr $leaveTime + 0.01] "$sgtrl($list($k)) join-group $rcvr $group"
            }
        }

        if {[array get gntl $list($k)] != []} {
            if {$gntl($list($k)) == "gateNode"} {
                $ns at $leaveTime "$list($k) leave-group $rcvr $group"
                $ns at [expr $leaveTime + 0.01] "$gtrl($list($k)) join-group $rcvr $group"

                $ns at [expr $leaveTime + 0.02] "$gtsgl($list($k)) leave-group $rcvr $group"
                $ns at [expr $leaveTime + 0.03] "$sgtrl($gtsgl($list($k))) join-group $rcvr $group"
            }
        }

        set leaveTime [expr $leaveTime + $joinLeaveInterval]
        incr k
    }
}

#Define a 'finish' procedure
proc finish {} {
    global ns f sfile userNum
    $ns flush-trace

    set awkCode {
        {
            if ($5 == "cbr") {
                if ($2 >= t_end_udp) {
                    tput_udp = bytes_udp * 8 / ($2 - t_start_udp)/1000;
                    print $2, tput_udp >> "tput-udp.tr";
                    t_start_udp = $2;
                    t_end_udp   = $2 + 2;
                    bytes_udp = 0;
                }
                if ($1 == "r") {
                    bytes_udp += $6;
                }
            }
        }
    }

    if { [info exists sfile] } {
        close $sfile
    }

    close $f

    exec rm -f tput-tcp.tr tput-udp.tr
    exec touch tput-tcp.tr tput-udp.tr
    exec awk $awkCode out.tr
    exec cp out.tr [append outTrName "out" $userNum ".tr"]
    exec cp tput-udp.tr [append tputUdpName "tput-udp" $userNum ".tr"]
    exec xgraph -bb -tk -m -x Seconds -y "Throughput (kbps)" tput-udp.tr &
    exec nam out.nam &
    exit 0
}

## 処理開始

setPacketColor $ns
set clusterNum 1
setNodeNum digestNodeNum gateNodeNum semiGateNodeNum nomalNodeNum notGetDigestNomalNum getDigestNomalNum joinNodeNum $userNum $clusterNum $digestUserRate $gateCommentRate $semiGateCommentRate $gateCommentRate $semiGateNodeNum $notGetDigestRate $finishTime

puts "１クラスタ当たりのノードの数\n"
puts "ダイジェストノード: \t\t\t$digestNodeNum"
puts "ゲートノード: \t\t\t\t$gateNodeNum"
puts "セミゲートノード: \t\t\t$semiGateNodeNum"
puts "ノーマルノード: \t\t\t$nomalNodeNum"
puts "ダイジェスト未取得ノーマルノード: \t$notGetDigestNomalNum"
puts "ダイジェスト取得済みノーマルノード: \t$getDigestNomalNum"

ratioSetting bandwidthRatio commentRatio $clusterNum $userNum

# 各ノードリストのinit処理
nodeListInit nodeList nodeListForBandwidth joinNodeList replaceGateNodeList replaceSemiGateNodeList replaceDigestNodeList $ns $userNum $finishTime $clusterNum $digestNodeNum $gateNodeNum $semiGateNodeNum $joinLeaveInterval
bandwidthListInit bandwidthList bandwidthRatio nodeListForBandwidth $ns $userNum
commentListInit commentList commentRatio nodeList $ns $userNum
nodeListForBandwidthShuffle nodeListForBandwidth $userNum


# 各役割のinit処理
rootNodeInit rootNode $ns
digestNodeInit digestNode digestNodeTypeList bandwidthList temporalBandwidthList nodeListForBandwidth nodeList $userNum $clusterNum $digestNodeNum
sortBandwidthList sortedBandwidthList bandwidthRatio bandwidthList
gateNodeInit gateNode gateNodeTypeList sortedBandwidthList $clusterNum $gateNodeNum
semiGateNodeInit semiGateNode semiGateNodeTypeList gateToSemiGateList sortedBandwidthList gateNode $clusterNum $semiGateNodeNum
nomalNodeInit nomalNotDigestNode nomalDigestNode gateNode semiGateNode sortedBandwidthList $clusterNum $notGetDigestNomalNum $getDigestNomalNum
joinNodeInit joinNode joinNodeList bandwidthRatio $clusterNum $finishTime
replaceGateNodeInit gateNode gateToReplaceList replaceGateNode replaceGateNodeList $clusterNum $gateNodeNum
replaceSemiGateNodeInit semiGateNode semiGateToReplaceList replaceSemiGateNode replaceSemiGateNodeList $clusterNum $semiGateNodeNum
replaceDigestNodeInit digestNode digestToReplaceList replaceDigestNode replaceDigestNodeList $clusterNum $digestNodeNum

puts "\nノードの数\n"
puts "ダイジェストノード: \t\t\t[array size digestNode]"
puts "ゲートノード: \t\t\t\t[array size gateNode]"
puts "セミゲートノード: \t\t\t[array size semiGateNode]"
puts "ダイジェスト未取得ノーマルノード: \t[array size nomalNotDigestNode]"
puts "ダイジェスト取得済みノーマルノード: \t[array size nomalDigestNode]"

# トレースファイルの設定
set f [open out.tr w]
$ns trace-all $f
set nf [open out.nam w]
$ns namtrace-all $nf

# 一時的にノードを削除していたので帯域幅リストを元に戻す
copy temporalBandwidthList bandwidthList

# クラスタ内部接続(クラスタの数実行)
for {set i 0} {$i < $clusterNum} {incr i} {
    connectGateNodeInCluster gateNode semiGateNode replaceGateNode bandwidthList $rootNode $ns $gateNodeNum $clusterNum $i
    connectSemiGateNode semiGateNode digestNode nomalDigestNode nomalNotDigestNode bandwidthList $ns $clusterNum $semiGateNodeNum $notGetDigestNomalNum $getDigestNomalNum $i
    connectDigestNode digestNode nomalNotDigestNode bandwidthList $ns $notGetDigestNomalNum $getDigestNomalNum $digestNodeNum $i
    connectNomalNode nomalDigestNode nomalNotDigestNode bandwidthList $ns $clusterNum $connectNomalNodeRate $notGetDigestNomalNum $getDigestNomalNum $nomalNodeNum $i
    connectJoinNode joinNode nomalDigestNode nomalNotDigestNode bandwidthList $ns $clusterNum $joinNodeNum $nomalNodeNum $i

    # 代わりゲートのノード接続
    connectReplaceGateNodeInCluster gateNode semiGateNode replaceGateNode bandwidthList $rootNode $ns $gateNodeNum $clusterNum $i
}

# 代わりのセミゲートノードの帯域幅設定
replaceSemiGateNodeBandwitdhSetting nomalDigestNode replaceSemiGateNode sortedBandwidthList bandwidthList $clusterNum

# 代わりのダイジェストノードの帯域幅設定
replaceDigestNodeBandwitdhSetting nomalDigestNode replaceDigestNode commentList bandwidthList $clusterNum

# クラスタ内部接続(クラスタの数実行, 代わりのセミゲートノードと代わりのダイジェストノード)
for {set i 0} {$i < $clusterNum} {incr i} {
    connectReplaceSemiGateNode semiGateNode digestNode nomalDigestNode nomalNotDigestNode replaceSemiGateNode bandwidthList $ns $clusterNum $semiGateNodeNum $notGetDigestNomalNum $getDigestNomalNum $i
    connectReplaceDigestNode digestNode nomalNotDigestNode replaceDigestNode bandwidthList $ns $notGetDigestNomalNum $getDigestNomalNum $digestNodeNum $i
}

# udp通信
UDPStreamInit mproto mrthandle group udp cbr rcvr sfile $ns $rootNode
attachInit nodeList joinNodeList replaceGateNodeList replaceSemiGateNodeList replaceDigestNodeList startTime $ns $rcvr $group

# 終了時間設定
set finishTime [expr $startTime + $finishTime]

# 新規参加ノード設定
newJoin joinNodeList $ns $rcvr $group $startTime $finishTime $joinLeaveInterval

# 離脱ノード設定
leaveNode nodeList joinNodeList replaceGateNodeList replaceSemiGateNodeList replaceDigestNodeList gateNodeTypeList semiGateNodeTypeList digestNodeTypeList gateToReplaceList semiGateToReplaceList digestToReplaceList gateToSemiGateList commentList $startTime $finishTime $joinLeaveInterval $ns $rcvr $group

$ns at $startTime "$cbr start"

$ns at $finishTime "finish"

$ns run
