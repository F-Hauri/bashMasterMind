#!/bin/bash

colorNames() {
    local i l
    cname=(blue green cyan red magenta yellow)
    for ((i=1;i<=numCol;i++)) ;do
        cval[${cname[i-1]:0:1}]=$i
        cletter+=(${cname[i-1]:0:1})
        IFS= read -rd '' cap[box$i] < <(
            tput -S <<<"setb $i"$'\n'"setf 7"$'\nbold')
        cap[box$i]+="${cletter[i-1]^}${cap[clr]}"
    done
}
doRandomReq() {
    local a=$[(numCol**numPos>32768?(numCol**numPos>1073741824?RANDOM<<30|
        RANDOM<<15|RANDOM:RANDOM<<15|RANDOM):RANDOM)%(numCol**numPos)] i
    for ((i=0;i<numPos;req[i]=a/numCol**(numPos-1-i),
          a-=req[i]*numCol**(numPos-1-i),req[i]++,i++)){ :; }
}
showReq() {
    local i out
    for i in ${req[@]};do
        out+=${cap[box$i]}\ 
    done
    printf 'Requested code was: [%s].\n' "${out% }"
}

doHead() {
    printf "Find in %d tries, right code of %d coulours, in:\n"\
           $numTries $numPos
    for ((i=1;i<=numCol;i++));do
        printf "%s (%s):%s %s " \
               ${cname[i-1]} ${cletter[i-1]} "${cap[box$i]}"
    done
    printf "\n\n"
}
showStep() {
    local i l=''
    for i in ${ans[@]};do
        l+=${cap[box$i]}\ 
    done
    tput cup $[turn*2+1] 2
    printf "Purpose %2d :  %s%s" $turn "$l" "${cap[eol]}"
}
del1col() {
    ((${#ans[@]})) && unset ans[${#ans[@]}-1]
}
usage() {
    cat <<-eousage
        Usage: $0 [-h] [-c NUM] [-p NUM] [-t NUM]
            -c NUM Number of colors ( 2 - 6, default $numCol).
            -p NUM Number of positions ( min 1, max depend on number of colors:
                      17 position if 6 colors, 19 if 5, 22 if 4, 28 if 3 and
                      upto 44 position if chosen on 2 colors. Default: $numPos).
            -t NUM Number of authorized tries. Default $numTries.
            -h     display this help.
        eousage
    exit $1
}

numCol=6   # min 2, max 6
numPos=4   # min 1, max=f(numCol): numCol=6->max=17, 5->19, 4->22, 3->28, 2->44
numTries=9

while getopts "c:p:t:" opt ;do
    case $opt in
        c ) numCol=$OPTARG ;;
        p ) numPos=$OPTARG ;;
        t ) numTries=$OPTARG ;;
        h ) usage ;;
        * ) usage 1 ;;
        esac
    done 
shift $[OPTIND-1]

(((numCol**numPos)>35184372088832)) && usage 1
(($#)) && usage 1

declare -A cval='()' cap='()'
IFS= read -rd '' cap[clr]   < <(tput sgr0)
IFS= read -rd '' cap[good]  < <(tput -S <<<$'setb 4\nsetf 7';echo +${cap[clr]})
IFS= read -rd '' cap[right] < <(tput -S <<<$'setb 7\nsetf 0';echo =${cap[clr]})
IFS= read -rd '' cap[eol]   < <(tput el)
cap[no]="${cap[clr]}_ "
win=false

clear
colorNames
doRandomReq
doHead

for ((turn=1;turn<=numTries;turn++));do
    combKey=
    while ((${#ans[@]}<numPos)) ;do
        showStep
        read -sn1 foo
        case "${foo,}" in
            q ) echo -- quit -- ; showReq ; exit 0;;
            $cletter | ${cletter[1]}  | ${cletter[2]}  | ${cletter[3]}  |\
                ${cletter[4]}  | ${cletter[5]} ) ans+=(${cval[${foo,}]}) ;;
            $'\177' ) del1col;;
            $'\e' ) combKey="$foo" ;;
            * ) combKey+="$foo";;
        esac
        [ "$combKey" = $'\e[3~' ] && combKey= && del1col
    done
    showStep
    tst=(${req[@]})
    o="";p=""
    for ((i=0;i<numPos;i++)) ;do
        [ "${tst[i]}" = "${ans[i]}" ] && ans[i]="+" tst[i]="-" p+="="
    done
    for ((i=0;i<numPos;i++)) ;do
        for ((j=0;j<numPos;j++)) ;do
            [ "${tst[i]}" = "${ans[j]}" ] && ans[j]="+" tst[i]="-" o+="+"
        done
    done

    printf -v e %$[numPos-${#p}-${#o}]s

    echo "  " ${p//=/${cap[right]} }${o//+/${cap[good]} }${e// /${cap[no]}}$'\n'
    ((${#p}==numPos)) && win=true && break
    ans=()
done

if $win ;then
    echo "You win!"
else
    echo "You loose!"
    showReq
fi
