#NS simulator object
set ns [new Simulator]

# デフォルトの値はここで定義
source my-goddard-default.tcl

# 共通の関数はここで定義
source my-goddard-procs.tcl

# 入力値(ユーザ数は必ず200の倍数)
set userNum [lindex $argv 0]

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

# ノードの数
set digestNodeNum 0
set gateNodeNum 0
set semiGateNodeNum 0
set nomalNodeNum 0
set notGetDigestNomalNum 0
set getDigestNomalNum 0

# ノードリスト
set nodeList(0) ""
set nodeListForBandwidth(0) ""

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
set sfile(0) ""
set gCount 0

# my-goddardのための関数
proc gateNodeInit {gateNode sortedBandwidthList clusterNum gateNodeNum} {
    upvar $gateNode gn $sortedBandwidthList sbl
    set k 0
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $gateNodeNum} {incr j} {
            set gn($i,$j) $sbl($k)
            # ゲートノードの色
            $gn($i,$j) color #006400
            incr k
        }
    }
    return
}
proc semiGateNodeInit {semiGateNode sortedBandwidthList gateNode clusterNum semiGateNodeNum} {
    upvar $semiGateNode sgn $sortedBandwidthList sbl $gateNode gn
    set k [array size gn]
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $semiGateNodeNum} {incr j} {
            set sgn($i,$j) $sbl($k)
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
    # 残りのノードはu全てダイジェスト取得済みノーマルノードへ
    set limit [expr [array size sbl]-$k]
    for {set i 0} {$i < $limit} {incr i} {
        set ndn($i,$getDigestNomalNum) $sbl($k)
        # ダイジェスト取得ノーマルノードの色
        $ndn($i,$getDigestNomalNum) color orange
        incr k
    }
    return
}
# この中で便宜上一時的に帯域幅リストからノードを削除している
proc digestNodeInit {digestNode bandwidthList temporalBandwidthList nodeListForBandwidth nodeList userNum clusterNum digestNodeNum} {
    upvar $digestNode dn $bandwidthList bl $temporalBandwidthList tbl $nodeListForBandwidth nlfb $nodeList nl
    copy bl tbl
    set commentI [expr $userNum-1]
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $digestNodeNum} {incr j} {
            set dn($i,$j) $nl($commentI)
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

# ノード間の接続
# 常に低いノード側の帯域幅で接続
# 帯域幅の設定する必要あり
proc connectGateNodeInCluster {gateNode semiGateNode bandwidthList rootNode ns gateNodeNum clusterNum selfClusterNum} {
    upvar $gateNode gn $semiGateNode sgn $bandwidthList bl
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
    for {set i 0} {$i < $semiGateNodeNum} {incr i} {
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
    for {set i 0} {$i < $semiGateNodeNum} {incr i} {
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
    for {set i 0} {$i < $digestNodeNum} {incr i} {
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
            if {[array get ndn $selfIndexNum,[expr $i-$notGetDigestNomalNum]] == []} {
                continue
            }
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
                if {[array get nomalNodeList $i] == []} {
                    continue
                }
                set bandwidth [returnLowBandwidth bl $nomalNodeList($i) $nomalNodeList([expr $i+$j+1-$nomalNodeNum])]
                $ns duplex-link $nomalNodeList($i) $nomalNodeList([expr $i+$j+1-$nomalNodeNum]) [expr $bandwidth]Mb 100ms DropTail
            } else {
                set bandwidth [returnLowBandwidth bl $nomalNodeList($i) $nomalNodeList([expr $i+$j+1])]
                $ns duplex-link $nomalNodeList($i) $nomalNodeList([expr $i+$j+1]) [expr $bandwidth]Mb 100ms DropTail
            }
        }
    }
}

#Define a 'finish' procedure
proc finish {} {
    global ns f gCount sfile userNum
    $ns flush-trace
    set awkCode {
        {
            if ($8 == 3000) {
                if ($2 >= t_end_tcp) {
                    tput_tcp = bytes_tcp * 8 / ($2 - t_start_tcp)/1000;
                    print $2, tput_tcp >> "tput-tcp.tr";
                    t_start_tcp = $2;
                    t_end_tcp = $2 + 2;
                    bytes_tcp = 0;
                }
                if ($1 == "r") {
                    bytes_tcp += $6;
                }
            }
            else if ($8 == 3001) {
                if ($2 >= t_end_udp) {
                    tput_udp = bytes_udp * 8 / ($2 - t_start_udp)/1000;
                    print $2, tput_udp >> "tput-udp.tr";
                    t_start_udp = $2;
                    t_end_udp = $2 + 2;
                    bytes_udp = 0;
                }
                if ($1 == "r") {
                    bytes_udp += $6;
                }
            }
        }
    }
    for {set i 0} {$i < $gCount} {incr i} {
        if { [info exists sfile($i)] } {
            close $sfile($i)
        }
    }
    close $f
    exec rm -f tput-tcp.tr tput-udp.tr
    exec touch tput-tcp.tr tput-udp.tr
    exec awk $awkCode out.tr
    exec cp out.nam [append outNamName "out" $userNum ".nam"]
    exec cp out.tr [append outTrName "out" $userNum ".tr"]
    exec cp tput-tcp.tr [append tputTcpName "tput-tcp" $userNum ".tr"]
    exec cp tput-udp.tr [append tputUdpName "tput-udp" $userNum ".tr"]
    exec xgraph -bb -tk -m -x Seconds -y "Throughput (kbps)" tput-tcp.tr tput-udp.tr &
    exec nam out.nam &
    exit 0
}

## 処理開始
setPacketColor $ns
setClusterNum clusterNum $userNum
setNodeNum digestNodeNum gateNodeNum semiGateNodeNum nomalNodeNum notGetDigestNomalNum getDigestNomalNum $userNum $clusterNum $digestUserRate $gateCommentRate $semiGateCommentRate $gateCommentRate $semiGateNodeNum $notGetDigestRate

puts "１クラスタ当たりのノードの数\n"
puts "ダイジェストノード: \t\t\t$digestNodeNum"
puts "ゲートノード: \t\t\t\t$gateNodeNum"
puts "セミゲートノード: \t\t\t$semiGateNodeNum"
puts "ノーマルノード: \t\t\t$nomalNodeNum"
puts "ダイジェスト未取得ノーマルノード: \t$notGetDigestNomalNum"
puts "ダイジェスト取得済みノーマルノード: \t$getDigestNomalNum"

ratioSetting bandwidthRatio commentRatio $clusterNum $userNum

# 各ノードリストのinit処理
nodeListInit nodeList nodeListForBandwidth $ns $userNum
bandwidthListInit bandwidthList bandwidthRatio nodeListForBandwidth $ns $userNum
commentListInit commentList commentRatio nodeList $ns $userNum
nodeListForBandwidthShuffle nodeListForBandwidth $userNum

# 各役割のinit処理
rootNodeInit rootNode $ns
digestNodeInit digestNode bandwidthList temporalBandwidthList nodeListForBandwidth nodeList $userNum $clusterNum $digestNodeNum
sortBandwidthList sortedBandwidthList bandwidthRatio bandwidthList
gateNodeInit gateNode sortedBandwidthList $clusterNum $gateNodeNum
semiGateNodeInit semiGateNode sortedBandwidthList gateNode $clusterNum $semiGateNodeNum
nomalNodeInit nomalNotDigestNode nomalDigestNode gateNode semiGateNode sortedBandwidthList $clusterNum $notGetDigestNomalNum $getDigestNomalNum

puts "\nノードの数\n"
puts "ダイジェストノード: \t\t\t[array size digestNode]"
puts "ゲートノード: \t\t\t\t[array size gateNode]"
puts "セミゲートノード: \t\t\t[array size semiGateNode]"
puts "ダイジェスト未取得ノーマルノード: \t[array size nomalNotDigestNode]"
puts "ダイジェスト取得済みノーマルノード: \t[array size nomalDigestNode]"

# namファイルの設定
set f [open out.tr w]
$ns trace-all $f
set nf [open out.nam w]
$ns namtrace-all $nf

# 一時的にノードを削除していたので帯域幅リストを元に戻す
copy temporalBandwidthList bandwidthList

# ゲートノードの数実行
for {set i 0} {$i < $gateNodeNum} {incr i} {
    connectGateNodeOutside gateNode bandwidthList ns $clusterNum $gateNodeNum $i
}

# クラスタの数実行
for {set i 0} {$i < $clusterNum} {incr i} {
    connectGateNodeInCluster gateNode semiGateNode bandwidthList $rootNode $ns $gateNodeNum $clusterNum $i
    connectSemiGateNode semiGateNode digestNode nomalDigestNode nomalNotDigestNode bandwidthList $ns $clusterNum $semiGateNodeNum $notGetDigestNomalNum $getDigestNomalNum $i
    connectDigestNode digestNode nomalNotDigestNode bandwidthList $ns $notGetDigestNomalNum $getDigestNomalNum $digestNodeNum $i
    connectNomalNode nomalDigestNode nomalNotDigestNode bandwidthList $ns $clusterNum $connectNomalNodeRate $notGetDigestNomalNum $getDigestNomalNum $nomalNodeNum $i
}

createNomalNodeStream nomalDigestNode nomalNotDigestNode digestNode goddard gplayer sfile gCount $rootNode $ns $clusterNum $getDigestNomalNum $notGetDigestNomalNum $digestNodeNum

# Scehdule Simulation
for {set i 0} {$i < $gCount} {incr i} {
    $ns at 0 "$goddard($i) start"
    $ns at 240.0 "$goddard($i) stop"
}

$ns at 240.0 "finish"

$ns run