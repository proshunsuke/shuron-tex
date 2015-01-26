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
set digestUserRate 0
set gateBandWidthRate 0
set gateCommentRate 0
set semiGateBandWidthRate 0
set semiGateCommentRate 0
set notGetDigestRate 0
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

# my-goddard-no-rollのための関数
proc nomalNodeInit {nomalDigestNode nomalNotDigestNode sortedBandwidthList clusterNum notGetDigestNomalNum getDigestNomalNum} {
    upvar $nomalDigestNode ndn $nomalNotDigestNode nndn $sortedBandwidthList sbl
    set k 0
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $getDigestNomalNum} {incr j} {
            set ndn($i,$j) $sbl($k)
            # ダイジェスト取得ノーマルノードの色
            $ndn($i,$j) color orange
            incr k
        }
    }
    # 残りのノードは全てダイジェスト取得済みノーマルノードへ
    set k [expr $k]
    set limit [expr [array size sbl]-$k]
    for {set i 0} {$i < $limit} {incr i} {
        set ndn($i,$getDigestNomalNum) $sbl($k)
        # ダイジェスト取得ノーマルノードの色
        $ndn($i,$getDigestNomalNum) color orange
        incr k
    }
    return
}

proc connectNomalNode {nomalDigestNode nomalNotDigestNode bandwidthList rootNode ns clusterNum connectNomalNodeRate notGetDigestNomalNum getDigestNomalNum nomalNodeNum selfIndexNum } {
    upvar $nomalDigestNode ndn $nomalNotDigestNode nndn $bandwidthList bl
    # とりあえずリストに全部入れる
    for {set i 0} {$i < [expr $nomalNodeNum+1]} {incr i} {
        if {[array get ndn $selfIndexNum,[expr $i-$notGetDigestNomalNum]] == []} {
            continue
        }
        set nomalNodeList($i) $ndn($selfIndexNum,[expr $i-$notGetDigestNomalNum])
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
    # 配信者ノード
    $ns duplex-link $nomalNodeList(0) $rootNode $bl($nomalNodeList(0))Mb 500ms DropTail
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
    exec xgraph -bb -tk -m -x Seconds -y "Throughput (kbps)" tput-tcp.tr tput-udp.tr &
    exec nam out.nam
    exec cp out.nam [append outNamName "out" $userNum "-no-roll.nam"]
    exec cp out.tr [append outTrName "out" $userNum "-no-roll.tr"]
    exec cp tput-tcp.tr [append tputTcpName "tput-tcp" $userNum "-no-roll.tr"]
    exec cp tput-udp.tr [append tputUdpName "tput-udp" $userNum "-no-roll.tr"]
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
sortBandwidthList sortedBandwidthList bandwidthRatio bandwidthList
nomalNodeInit nomalDigestNode nomalNotDigestNode sortedBandwidthList $clusterNum $notGetDigestNomalNum $getDigestNomalNum

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

# クラスタの数実行
for {set i 0} {$i < $clusterNum} {incr i} {
    connectNomalNode nomalDigestNode nomalNotDigestNode bandwidthList $rootNode $ns $clusterNum $connectNomalNodeRate $notGetDigestNomalNum $getDigestNomalNum $nomalNodeNum $i
}

createNomalNodeStream nomalDigestNode nomalNotDigestNode digestNode goddard gplayer sfile gCount $rootNode $ns $clusterNum $getDigestNomalNum $notGetDigestNomalNum $digestNodeNum

# Scehdule Simulation
for {set i 0} {$i < $gCount} {incr i} {
    $ns at 0 "$goddard($i) start"
    $ns at 240.0 "$goddard($i) stop"
}

$ns at 240.0 "finish"

$ns run
