#!/bin/bash
###############################################################################
#
#  GPU - Algorithmus - Berechnung - BTC "Mines" anhand aktueller Kurse
#
#  1. Neustart des Skripts bekommt eine PID, die nur in der Prozesstabelle vorhanden ist
#  2. Merkt sich die eigene UUID in ${GPU_DIR}
#  3. Definiert _update_SELF_if_necessary()
#  4. Ruft update_SELF_if_necessary()
#  5. Schreibt seine PID in eine gleichnamige Datei mit der Endung .pid
#  6. Prüft, ob die Benchmarkdatei jemals bearbeitet wurde und bricht ab, wenn nicht.
#     Dann gibt es nämlich keine Benchmark- und Wattangaben zu den einzelnen Algorithmen.
#  7. Definiert _read_IMPORTANT_BENCHMARK_JSON_in(), welches Benchmark- und Wattangaben pro Algorithmus
#     aus der Datei benchmark_${GPU_DIR}.json
#     in die Assoziativen Arrays bENCH["AlgoName"] und WATTS["AlgoName"] aufnimmt
#  8. Ruft _read_IMPORTANT_BENCHMARK_JSON_in() und hat jetzt die beiden Arrays zur Verfügung und kennt das "Alter"
#     der Benchmarkdatei zum Zeitpunkt des Einlesens in der Variablen ${IMPORTANT_BENCHMARK_JSON_last_age_in_seconds}
# (21.11.2017)
# Wir wissen jetzt, dass alle relevanten Werte in der "simplemultialgo"-api Abfrage enthalten sind
#     und brauchen die ../ALGO_NAMES.in überhaupt nicht mehr.
#     Das folgende kann raus:
#  9. 
#
# (21.11.2017)
# Das machen wir ANDERS. Es gibt schon includable Funktionen zum Abruf, Auswertung und Einlesen der Webseite
# in die Arrays durch source ${LINUX_MULTI_MINING_ROOT}/algo_infos.inc
#        ALGOs[ $algo_ID ]
#        KURSE[ $algo ]
#        PORTs[ $algo ]
#     ALGO_IDs[ $algo ]
# 10. source ${LINUX_MULTI_MINING_ROOT}/algo_infos.inc
#
# 11. ###WARTET### jetzt, bis das SYNCFILE="../you_can_read_now.sync" vorhanden ist.
#                         und merkt sich dessen "Alter" in der Variable ${new_Data_available}
#
# (21.11.2017)
# Wir wissen jetzt, dass alle relevanten Werte in der "simplemultialgo"-api Abfrage enthalten sind
#     und brauchen die ../ALGO_NAMES.in überhaupt nicht mehr.
#     Das folgende kann raus:
# 12. 
# 13. 
#
# 14. EINTRITT IN DIE ENDLOSSCHLEIFE. Die folgenden Aktionen werden immer und immer wieder durchgeführt,
#                                     solange dieser Prozess läuft.
#  1. Ruft _update_SELF_if_necessary
#  2. Ruft _read_IMPORTANT_BENCHMARK_JSON_in falls die Quelldatei upgedated wurde.
#                                        => Aktuelle Arrays bENCH["AlgoName"] und WATTS["AlgoName"]
#  3. (weggefallen)
#  4. ###WARTET### jetzt, bis die Datei "../KURSE_PORTS.in" vorhanden und NICHT LEER ist.
#  5. Ruft _read_in_ALGO_PORTS_KURSE     => Array KURSE["AlgoName"] verfügbar
#  6. Berechnet jetzt die "Mines" in BTC und schreibt die folgenden Angaben in die Datei ALGO_WATTS_MINES.in :
#               AlgoName
#               Watt
#               BTC "Mines"
#     sofern diese Daten tatsächlich vorhanden sind.
#     Algorithmen mit fehlenden Benchmark- oder Wattangaben, etc. werden NICHT beachtet.
#
#     Das "Alter" der Datei ALGO_WATTS_MINES.in Sekunden ist Hinweis für multi_mining_calc.sh,
#     ob mit der Gesamtsystem-Gewinn-Verlust-Berechnung begonnen werden kann.
#
#  7. Die Daten für multi_mining_calc.sh sind nun vollständig verfügbar.
#     Es ist jetzt erst mal die Berechnung durch multi_mining_calc.sh abzuwarten, um wissen zu können,
#     ob diese GPU ein- oder ausgeschaltet werden soll.
#     Vielleicht können wir das sogar hier drin tun, nachdem das Ergebnis für diese GPU feststeht ???
#
#  8. Wenn multi_mining_calc.sh mit den Berechnungen fertig ist, schreibt sie die Datei ${RUNNING_STATE},
#     in der die neue Konfigurationdrin steht, WIE ES AB JETZT ZU SEIN HAT.
#     Aus dieser Datei entnimmt jede GPU nun die Information, die für sie bestimmt ist und stoppt und startet
#     die entsprechenden Miner.
#     Miner, die noch laufen, müssen beendet werden, wenn ein neuer Miner gestartet werden soll.
#     Nach jedem Minerstart merkt sich die GPU, 
#
#     ###WARTET### jetzt, bis das "Alter" der Datei ${SYNCFILE} aktueller ist als ${new_Data_available}
#                         mit der Meldung "Waiting for new actual Pricing Data from the Web..."
#  9. Merkt sich das neue "Alter" von ${SYNCFILE} in der Variablen ${new_Data_available}
#
# 15. VORLÄUFIGES ENDE DER ENDLOSSCHLEIFE
#
###############################################################################
#  1. Neustart des Skripts bekommt eine PID, die nur in der Prozesstabelle vorhanden ist
#  2. Merkt sich die eigene UUID in ${GPU_DIR}
SRC_DIR=GPU-skeleton
GPU_DIR=$(pwd | gawk -e 'BEGIN { FS="/" }{print $NF}')
#  3. Definiert _update_SELF_if_necessary()
_update_SELF_if_necessary()
{
    ###
    ### DO NOT TOUCH THIS FUNCTION! IT UPDATES ITSELF FROM DIR "GPU-skeleton"
    ###
    SRC_FILE=$(basename $0)
    UPD_FILE="update_${SRC_FILE}"
    rm -f $UPD_FILE
    if [ ! "$GPU_DIR" == "$SRC_DIR" ]; then
        src_secs=$(date --utc --reference=../${SRC_DIR}/${SRC_FILE} +%s)
        dst_secs=$(date --utc --reference=$SRC_FILE +%s)
        if [[ $dst_secs < $src_secs ]]; then
            # create update command file
            echo "cp -f ../${SRC_DIR}/${SRC_FILE} .; \
                  exec ./${SRC_FILE}" \
                 >$UPD_FILE
            chmod +x $UPD_FILE
            echo "GPU #$(< gpu_index.in): ###---> Updating the GPU-UUID-directory from $SRC_DIR"
            exec ./$UPD_FILE
        fi
    else
        echo "Exiting in the not-to-be-run $SRC_DIR directory"
        echo "This directory doesn't represent a valid GPU"
        exit 2
    fi
}
# Beim Neustart des Skripts gleich schauen, ob es eine aktuellere Version gibt
# und mit der neuen Version neu starten.
#  4. Ruft update_SELF_if_necessary()
_update_SELF_if_necessary

# GLOBALE VARIABLEN, nützliche Funktionen
[[ ${#_GLOBALS_INCLUDED} -eq 0 ]] && source ../globals.inc
declare -i verbose=0
declare -i debug=0

# Mehr und mehr setzt sich die Systemweite Verwendung dieser Variablen durch:
gpu_idx=$(< gpu_index.in)
if [ ${#gpu_idx} -eq 0 ]; then
    declare -i i=0
    declare -i n=5
    for (( ; i<n; i++ )); do
        clear
        echo "---===###>>> MISSING IDENTITY:"
        echo "---===###>>> Ist gpu-abfrage.sh nicht gelaufen?"
        echo "---===###>>> Mir fehlt die Datei gpu_index.in, die mir sagt,"
        echo "---===###>>> welchen GPU-Index ich als UUID"
        echo "---===###>>> ${GPU_DIR}"
        echo "---===###>>> gerade habe."
        echo "---===###>>> Der Aufruf wird in $((n-i)) Sekunden gestoppt und beendet!"
        sleep 1
    done
    exit 1
fi    

# Diese Prozess-ID ändert sich durch den Selbst-Update NICHT!!!
# Sie ist auch nach dem Selbst-Update noch die Selbe.
# Es ist immer noch der selbe Prozess.
# Diese Datei sollte aber auch immer zusammen mit dem Prozess verschwinden, was wir noch konstruieren müssen.
#  5. Schreibt seine PID in eine gleichnamige Datei mit der Endung .pid
echo $$ >$(basename $0 .sh).pid

#
# Aufräumarbeiten beim ordungsgemäßen kill -15 Signal
#
function _On_Exit () {
    # Die MinerShell muss beendet werden, wenn sie noch laufen sollte.
    MinerShell_pid=$(< ${MinerShell}.ppid)
    if [ ${#MinerShell_pid} -gt 0 ]; then
        printf "Beenden der MinerShell ${MinerShell}.sh mit PID ${MinerShell_pid} ... "
        kill_pids=$(ps -ef \
              | grep -e "${MinerShell_pid}" -e "\./${MinerShell}\.sh" \
              | grep -v 'grep -e ' \
              | gawk -e 'BEGIN {pids=""} {pids=pids $2 " "} END {print pids}')
        if [ ! "$kill_pids" == "" ]; then
            kill $kill_pids # >/dev/null
            printf "done.\n"
        else
            printf "NOT FOUND!!!\n"
        fi
    fi

    rm -f .DO_AUTO_BENCHMARK_FOR
    for algorithm in ${!DO_AUTO_BENCHMARK_FOR[@]}; do
        echo $algorithm >>.DO_AUTO_BENCHMARK_FOR
    done
    rm -f LINUX_MULTI_MINING_ROOT *.lock ${MinerShell}.ppid ${MinerShell}.sh \
       $(basename $0 .sh).pid
}
trap _On_Exit EXIT

# Die Quelldaten Miner- bzw. AlgoName, BenchmarkSpeed und WATT für diese GraKa
#  6. Prüft, ob die Benchmarkdatei jemals bearbeitet wurde und bricht ab, wenn nicht.
#     Dann gibt es nämlich keine Benchmark- und Wattangaben zu den einzelnen Algorithmen.
IMPORTANT_BENCHMARK_JSON_SRC=../${SRC_DIR}/benchmark_skeleton.json
IMPORTANT_BENCHMARK_JSON="benchmark_${GPU_DIR}.json"
diff -q $IMPORTANT_BENCHMARK_JSON $IMPORTANT_BENCHMARK_JSON_SRC &>/dev/null
if [ $? == 0 ]; then
    echo "-------------------------------------------"
    echo "---        FATAL ERROR GPU #${gpu_idx}           ---"
    echo "-------------------------------------------"
    echo "File '$IMPORTANT_BENCHMARK_JSON' not yet edited!!!"
    echo "Please edit and fill in valid data!"
    echo "Execution stopped."
    echo "-------------------------------------------"
    exit 1
fi
gpu_uuid="${GPU_DIR}"

###############################################################################
#
# Einlesen und verarbeiten der Benchmarkdatei
#
######################################

#  7. Definiert _read_IMPORTANT_BENCHMARK_JSON_in(), welches Benchmark- und Wattangaben
#     und überhaupt alle Daten pro Algorithmus
#     aus der Datei benchmark_${GPU_DIR}.json
#     in die Assoziativen Arrays bENCH["AlgoName"] und WATTS["AlgoName"] und
#     MAX_WATT["AlgoName"]
#     HASHCOUNT["AlgoName"]
#     HASH_DURATION["AlgoName"]
#     BENCH_DATE["AlgoName"]
#     BENCH_KIND["AlgoName"]
#     MinerFee["AlgoName"]
#     EXTRA_PARAMS["AlgoName"]
#     GRAFIK_CLOCK["AlgoName"]
#     MEMORY_CLOCK["AlgoName"]
#     FAN_SPEED["AlgoName"]
#     POWER_LIMIT["AlgoName"]
#     LESS_THREADS["AlgoName"]
#     aufnimmt
#
#     (09.11.2017)
#     Nach jedem Einlesen der Algorithmen aus der IMPORTANT_BENCHMARK_JSON prüft diese Funktion ebenfalls,
#     wie viele Miner in wieviel verschiedenen Versionen insgesamt im System bekannt sind
#         und welche Algorithmen sie können,
#     DAMIT bekannt ist, wie viele Algorithmen es insgesamt im System gibt, die alle miteinander verglichen werden können.
#
#     Algorithmen, die MÖGLICH, aber noch nicht in der IMPORTANT_BENCHMARK_JSON enthalten sind,
#         werden durch eine entsprechende Meldung "angemeckert".
#
#     ---> Natürlich muss noch überlegt werden,                                     <---
#     ---> an welcher Stelle eine routinemäßige Prüfung aller möglichen Algorithmen <---
#     ---> stattfinden soll, um keine Änderung im System zu verpassen.              <---
#     
bENCH_SRC="bENCH.in"
# Ein bisschen Hygiene bei Änderung von Dateinamen
bENCH_SRC_OLD=""; if [ -f "$bENCH_SRC_OLD" ]; then rm "$bENCH_SRC_OLD"; fi

# Damit readarray als letzter Prozess in einer Pipeline nicht in einer subshell
# ausgeführt wird und diese beim Austriit gleich wieder seine Variablen verwirft
shopt -s lastpipe
source gpu-bENCH.sh

# Auf jeden Fall beim Starten das Array bENCH[] und WATTS[] aufbauen
# Später prüfen, ob die Datei erneuert wurde und frisch eingelesen werden muss
#  8. Ruft _read_IMPORTANT_BENCHMARK_JSON_in() und hat jetzt die beiden Arrays zur Verfügung und kennt das "Alter"
#     der Benchmarkdatei zum Zeitpunkt des Einlesens in der Variablen ${IMPORTANT_BENCHMARK_JSON_last_age_in_seconds}
_read_IMPORTANT_BENCHMARK_JSON_in

###############################################################################
#
# Die Funktionen zum Einlesen und Verarbeiten der aktuellen Algos und Kurse
#
#
#
######################################

# 10. Definiert _read_in_ALGO_PORTS_KURSE(), welches die Datei "../KURSE_PORTS.in" in das Array KURSE["AlgoName"] aufnimmt.
#     Das Alter dieser Datei ist unwichtig, weil sie IMMER durch algo_multi_abfrage.sh aus dem Web aktualisiert wird.
#     Andere müssen dafür sorgen, dass die Daten in dieser Datei gültig sind!
[[ ${#_ALGOINFOS_INCLUDED} -eq 0 ]] && source ${LINUX_MULTI_MINING_ROOT}/algo_infos.inc
[[ ${#_NVIDIACMD_INCLUDED} -eq 0 ]] && source ${LINUX_MULTI_MINING_ROOT}/benchmarking/nvidia-befehle/nvidia-query.inc
[[ ${#_MINERFUNC_INCLUDED} -eq 0 ]] && source ${LINUX_MULTI_MINING_ROOT}/miner-func.inc

###############################################################################
#
# Gibt es überhaupt schon etwas zu tun?
#
######################################

# Diese Datei wird alle 31s erstelt, nachdem die Daten aus dem Internet aktualisiert wurden
# Sollte diese Datei nicht da sein, weil z.B. die algo_multi_abfrage.sh
# noch nicht gelaufen ist, warten wir das einfach ab und sehen sekündlich nach,
# ob die Datei nun da ist und die Daten zur Verfügung stehen.

# 11. ###WARTET### jetzt, bis das SYNCFILE="../you_can_read_now.sync" vorhanden ist.
#                         und merkt sich dessen "Alter" in der Variable ${new_Data_available}
_progressbar='\r'
while [ ! -f ${SYNCFILE} ]; do
    [[ "${_progressbar}" == "\r" ]] && echo "GPU #${gpu_idx}: ###---> Waiting for ${SYNCFILE} to become available..."
    _progressbar+='.'
    if [[ ${#_progressbar} -gt 75 ]]; then
        printf '\r                                                                            '
        _progressbar='\r.'
    fi
    printf ${_progressbar}
    sleep .5
done
[[ "${_progressbar}" != "\r" ]] && printf "\n"
new_Data_available=$(date --utc --reference=${SYNCFILE} +%s)

###############################################################################
#
#     ENDLOSSCHLEIFE START
#
#
# 14. EINTRITT IN DIE ENDLOSSCHLEIFE. Die folgenden Aktionen werden immer und immer wieder durchgeführt,
#                                     solange dieser Prozess läuft.
while :; do
    
    echo ""
    echo $(date "+%Y-%m-%d %H:%M:%S" ) $(date +%s)
    echo "GPU #${gpu_idx}: ###---> Wieder am Anfang der Endlosschleife <---###"

    # If there is a newer version of this script, update it before the next run
    #  1. Ruft _update_SELF_if_necessary
    _update_SELF_if_necessary

    # Ist die Benchmarkdatei mit einer aktuellen Version überschrieben worden?
    #  2. Ruft _read_IMPORTANT_BENCHMARK_JSON_in falls die Quelldatei upgedated wurde.
    #                             => Aktuelle Arrays bENCH["AlgoName"] und WATTS["AlgoName"]
    if [[ $IMPORTANT_BENCHMARK_JSON_last_age_in_seconds < $(date --utc --reference=$IMPORTANT_BENCHMARK_JSON +%s) ]]; then
        echo "GPU #${gpu_idx}: ###---> Updating Arrays bENCH[] and WATTs[] (and more) from $IMPORTANT_BENCHMARK_JSON"
        _read_IMPORTANT_BENCHMARK_JSON_in
    fi

    # Die Reihenfolge der Dateierstellungen durch ../algo_multi_abfrage.sh ist:
    # (21.11.2017)
    # Wir wissen jetzt, dass alle relevanten Werte in der "simplemultialgo"-api Abfrage enthalten sind
    #     und brauchen die ../ALGO_NAMES.in überhaupt nicht mehr.
    #     Das folgende kann raus und es ergibt sich eine neue Reihenfolge:
    #     (1.: $ALGO_NAMES entfällt)
    #     1.: $algoID_KURSE_PORTS_WEB und $algoID_KURSE_PORTS_ARR
    #     2.: ../BTC_EUR_kurs.in
    # Letzte: ${SYNCFILE}

    # (29.11.2017)
    # Wir lesen jetzt den aktuellen Status ein, falls die Schleife schon mal gelaufen ist bzw.
    #     wenn die multi_mining_calc.sh sie schon mal festgelegt hat.
    # Wenn da etwas ist, dann läuft möglicherweise gerade ein Miner, der hier gestartet wurde.
    # Da die Datei ${RUNNING_STATE} erst wieder geschrieben wird, nachdem die ALG_WATTS_MINES.in Berechnungen hier abgeliefert worden sind,
    # sperren wir sie mal NICHT zum Lesen, weil gleichzeitiges Lesen kein Problem verursachen sollte.
    unset IamEnabled MyActWatts RuningAlgo
    #_reserve_and_lock_file ${RUNNING_STATE}          # Zum Lesen reservieren...
    _read_in_actual_RUNNING_STATE                    # ... einlesen...
    #rm -f ${RUNNING_STATE}.lock                      # ... und wieder freigeben
    if [ ${#RunningGPUid[${gpu_uuid}]} -gt 0 ]; then
        [[ "${RunningGPUid[${gpu_uuid}]}" != "${gpu_idx}" ]] \
            && echo "Konsistenzcheck FEHLGESCHLAGEN!!! GPU-Idx aus RUNNING_STATE anders als er sein soll !!!"
        IamEnabled=${WasItEnabled[${gpu_uuid}]}
        MyActWatts=${RunningWatts[${gpu_uuid}]}
        RuningAlgo=${WhatsRunning[${gpu_uuid}]}
    fi

    if [ $debug -eq 1 ]; then
        echo $(date "+%Y-%m-%d %H:%M:%S" ) $(date +%s)
        echo "GPU #${gpu_idx}: Einlesen und verarbeiten der aktuellen Kurse, sobald die Datei vorhanden und nicht leer ist"
    fi
    #  4. ###WARTET### jetzt, bis die Datei "../KURSE_PORTS.in" vorhanden und NICHT LEER ist.
    _progressbar='\r'
    while [ ! -s ${algoID_KURSE_PORTS_ARR} ]; do
        [[ "${_progressbar}" == "\r" ]] \
            && echo "GPU #${gpu_idx}: ###---> Waiting for ${algoID_KURSE_PORTS_ARR} to become available..."
        _progressbar+='.'
        if [[ ${#_progressbar} -gt 75 ]]; then
            printf '\r                                                                            '
            _progressbar='\r.'
        fi
        printf ${_progressbar}
        sleep .5
    done
    [[ "${_progressbar}" != "\r" ]] && printf "\n"
    #  5. Ruft _read_in_ALGO_PORTS_KURSE     => Array KURSE["AlgoName"] verfügbar
    #                                        => Array PORTS["AlgoName"] verfügbar
    #                                        => Array ALGOs["Algo_IDs"] verfügbar
    #                                        => Array ALGO_IDs["AlgoName"] verfügbar
    _read_in_ALGO_PORTS_KURSE

    ###############################################################################
    #
    #    Ermittlung aller Algos, die zu Enablen sind und die Algos, die Disabled sind.
    #
    ######################################
    _reserve_and_lock_file ../MINER_ALGO_DISABLED_HISTORY

    nowDate=$(date "+%Y-%m-%d %H:%M:%S" )
    declare -i nowSecs=$(date +%s)
    unset MINER_ALGO_DISABLED_ARR MINER_ALGO_DISABLED_DAT
    declare -Ag MINER_ALGO_DISABLED_ARR MINER_ALGO_DISABLED_DAT
    if [ -f ../MINER_ALGO_DISABLED ]; then
        if [ $debug -eq 1 ]; then echo "Reading ../MINER_ALGO_DISABLED ..."; fi
        declare -i timestamp
        unset READARR
        readarray -n 0 -O 0 -t READARR <../MINER_ALGO_DISABLED
        for ((i=0; $i<${#READARR[@]}; i++)) ; do
            read _date_ _oclock_ timestamp algorithm <<<${READARR[$i]}
            MINER_ALGO_DISABLED_ARR[${algorithm}]=${timestamp}
            MINER_ALGO_DISABLED_DAT[${algorithm}]="${_date_} ${_oclock_}"
        done
        # Jetzt sind die Algorithm's unique und wir prüfen nun, ob welche dabei sind,
        # die wieder zu ENABLEN sind, bzw. die aus dem Disabled_ARR verschwinden müssen,
        # bevor wir die Datei neu schreiben.
        for algorithm in "${!MINER_ALGO_DISABLED_ARR[@]}"; do
            if [ ${nowSecs} -gt $(( ${MINER_ALGO_DISABLED_ARR[${algorithm}]} + 300 )) ]; then
                # Der Algo ist wieder einzuschalten
                unset MINER_ALGO_DISABLED_ARR[${algorithm}]
                unset MINER_ALGO_DISABLED_DAT[${algorithm}]
                printf "ENABLED ${nowDate} ${nowSecs} ${algorithm}\n" | tee -a ../MINER_ALGO_DISABLED_HISTORY
            fi
        done
        # Weg mit dem bisherigen File...
        mv -f ../MINER_ALGO_DISABLED ../MINER_ALGO_DISABLED.BAK
        # ... und anlegen eines Neuen, wenn noch Algos im Array sind
        for algorithm in "${!MINER_ALGO_DISABLED_ARR[@]}"; do
            # Die eingelesenen Werte wieder ausgeben
            printf "${MINER_ALGO_DISABLED_DAT[${algorithm}]} ${MINER_ALGO_DISABLED_ARR[${algorithm}]} ${algorithm}\n" >>../MINER_ALGO_DISABLED
        done
    fi

    rm -f ../MINER_ALGO_DISABLED_HISTORY.lock

    #    Zusätzlich die über BENCH_ALGO_DISABLED Algos rausnehmen...
    if [ -f ../BENCH_ALGO_DISABLED ]; then
        unset BENCH_ALGO_DISABLED_ARR
        cat ../BENCH_ALGO_DISABLED | grep -E -v -e '^#|^$' | readarray -n 0 -O 0 -t BENCH_ALGO_DISABLED_ARR
    fi

    #    Zusätzlich die über GLOBAL_ALGO_DISABLED Algos rausnehmen...
    if [ -f ../GLOBAL_ALGO_DISABLED ]; then
        unset GLOBAL_ALGO_DISABLED_ARR
        cat ../GLOBAL_ALGO_DISABLED | grep -E -v -e '^#|^$' | readarray -n 0 -O 0 -t GLOBAL_ALGO_DISABLED_ARR
        if [ $debug -eq 1 ]; then echo "Die Datei GLOBAL_ALGO_DISABLED hat ${#GLOBAL_ALGO_DISABLED_ARR[@]} Einträge"; fi
        for ((i=0; $i<${#GLOBAL_ALGO_DISABLED_ARR[@]}; i++)) ; do
            unset disabled_algos_GPUs
            read -a disabled_algos_GPUs <<<${GLOBAL_ALGO_DISABLED_ARR[$i]//:/ }
            if [ ${#disabled_algos_GPUs[@]} -gt 1 ]; then
                # Nur für bestimmte GPUs disabled. Wenn die eigene GPU nicht aufgeführt ist, übergehen
                if [[ ${GLOBAL_ALGO_DISABLED_ARR[$i]} =~ ^.*:${gpu_uuid} ]]; then
                    GLOBAL_ALGO_DISABLED_ARR[$i]=${disabled_algos_GPUs[0]}
                else
                    unset GLOBAL_ALGO_DISABLED_ARR[$i]
                fi
            fi
        done
        if [ $debug -eq 1 ]; then
            echo "GPU #${gpu_idx}: Das GLOBAL_ALGO_DISABLED_ARRAY hat ${#GLOBAL_ALGO_DISABLED_ARR[@]} Einträge"
            declare -p GLOBAL_ALGO_DISABLED_ARR
        fi
    fi

    ###############################################################################
    #
    #    Berechnung und Ausgabe ALLER (Enabled und bezahlten) AlgoNames, Watts und Mines für die Multi_mining_calc.sh
    #
    ######################################

    # Zur sichereren Synchronisation, dass der multi_mining_calc.sh erst dann die Datei ALGO_WATTS_MINES
    # einliest, wenn sie auch komplett ist und geschlossen wurde.
    nowSecs=$(date +%s)
    echo ${nowSecs} >ALGO_WATTS_MINES.lock
    if [ $debug -eq 1 ]; then echo "GPU #${gpu_idx}: Locking ALGO_WATTS_MINES.in by writing ALGO_WATTS_MINES.lock at ${nowSecs}"; fi
    #  6. Berechnet jetzt die "Mines" in BTC und schreibt die folgenden Angaben in die Datei ALGO_WATTS_MINES.in :
    #               AlgoName
    #               Watt
    #               BTC "Mines"
    #     sofern diese Daten tatsächlich vorhanden sind.
    #     Algorithmen mit fehlenden Benchmark- oder Wattangaben, etc. werden NICHT beachtet.
    #
    #     Das "Alter" der Datei ALGO_WATTS_MINES.in Sekunden ist Hinweis für multi_mining_calc.sh,
    #     ob mit der Gesamtsystem-Gewinn-Verlust-Berechnung begonnen werden kann.
    rm -f ALGO_WATTS_MINES.in
    for algorithm in "${!bENCH[@]}"; do

        # Manche Algos kommen erst gar nicht in die Datei rein, z.B. wenn sie DISABLED wurden
        # oder wenn gerade nichts dafür bezahlt wird.

        # Wenn der Algo für 5 Minuten Disabled ist, übergehen:
        [[ ${#MINER_ALGO_DISABLED_ARR[${algorithm%#888}]} -ne 0 ]] && continue
        # Wenn der Algo durch BENCHMARKING PERMANENT Disabled ist, übergehen:
        for algo in ${BENCH_ALGO_DISABLED_ARR[@]}; do
            [[ "${algorithm%#888}" == "${algo}" ]] && continue 2
        done
        # Wenn der Algo GLOBAL Disabled ist, übergehen:
        for algo in ${GLOBAL_ALGO_DISABLED_ARR[@]}; do
            [[ ${algorithm} =~ ^${algo} ]] && continue 2
        done

        read algo miner_name miner_version muck888 <<<${algorithm//#/ }
        # Wenn gerade nichts für den Algo bezahlt wird, übergehen:
        [[ "${KURSE[$algo]}" == "0" ]] && continue

        if [[          ${#bENCH[$algorithm]} -gt 0   \
                    && ${#KURSE[$algo]}      -gt 0   \
                    && ${WATTS[$algorithm]}  -lt 1000 \
            ]]; then
            # "Mines" in BTC berechnen
            algoMines=$(echo "scale=8;   ${bENCH[$algorithm]}  \
                                       * ${KURSE[$algo]}  \
                                       / ${k_base}^3  \
                             " | bc )
            printf "$algorithm\n${WATTS[$algorithm]}\n${algoMines}\n" >>ALGO_WATTS_MINES.in
        else
            echo "GPU #${gpu_idx}: KEINE BTC \"Mines\" BERECHNUNG möglich bei $algorithm !!! \<---------------"
            DO_AUTO_BENCHMARK_FOR["$algorithm"]=1
        fi
    done
    rm -f ALGO_WATTS_MINES.lock
    if [ $debug -eq 1 ]; then nowSecs=$(date +%s); echo "GPU #${gpu_idx}: ALGO_WATTS_MINES.in UNLOCKED at ${nowSecs}"; fi
    
    #############################################################################
    #############################################################################
    #
    #  7. Die Daten für multi_mining_calc.sh sind nun vollständig verfügbar.
    #     Es ist jetzt erst mal die Berechnung durch multi_mining_calc.sh abzuwarten, um wissen zu können,
    #     ob diese GPU ein- oder ausgeschaltet werden soll.
    #     Vielleicht können wir das sogar hier drin tun, nachdem das Ergebnis für diese GPU feststeht ???
    #
    #############################################################################
    #############################################################################


    # multi_mining_calc.sh rechnet...


    #############################################################################
    #############################################################################
    #
    #  8. Wenn multi_mining_calc.sh mit den Berechnungen fertig ist, schreibt sie die Datei ${RUNNING_STATE},
    #     in der die neue Konfigurationdrin steht, WIE ES AB JETZT ZU SEIN HAT.
    #     Aus dieser Datei entnimmt jede GPU nun die Information, die für sie bestimmt ist und stoppt und startet
    #     die entsprechenden MinerShells.
    #
    #     Eine MinerShell ist nicht der Miner selbst, sondern ein .sh Script, das den übergebenen Miner
    #          sowie ein Terminalfenster mit seiner Logdatei startet.
    #     Die MinerShell hat jetzt die alleinige Verantwortung, diesen Miner so lange wie möglich laufen zu lassen.
    #          Ein Abbruch erfolgt von hier aus, von "aussen", sozusagen, es sei denn...
    #
    #     Die MinerShell überwacht dabei selbst das Miner-Logfile, um Unregelmäßigkeiten zu entdecken
    #          und entsprechend darauf zu reagieren, z.B.:
    #          - Verbindungsaufbau oder -abbruch zu NiceHash Server bedeutet: "continent" wechseln
    #            und beobachten, ob dann was geht (beim Aufbau innerhalb der ersten 5 Sekunden)
    #            ODER ob der Miner abzubrechen ist und weitere Maßnahmen ergriffen werden müssen,
    #            wie z.B. den Algo für diesen Miner vorübergehend DISABLEN ???   <--------------------------------
    #          - 90s ohne einen Hashwert bedeutet auch, dass etwas mit dem Algo nicht stimmt.
    #          - zu viele booooos und rejects (10 Aufeinanderfolgende) zeigen auch, dass mit dem Algo was nicht stimmt.
    #          - to be continued...
    #
    #     Miner, die noch laufen, müssen beendet werden, wenn ein neuer Miner gestartet werden soll.
    #     Nach jedem Minerstart merkt sich die GPU in dem File ${MinerShell}.ppid die gestartete MinerShell
    #          und kann sie so beenden.
    #     Ein Abbruch der MinerShell beendet ihrerseits die zwei von ihr gestarteten Prozesse Miner und Log-Terminal
    #
    #############################################################################
    #############################################################################
    echo "GPU #${gpu_idx}: Waiting for new RUNNING_STATE to get orders..."
    while [[ ! -f ${RUNNING_STATE} ]] \
              || [[ $(stat -c %Y ${RUNNING_STATE}) -lt ${new_Data_available} ]] \
              || [[ -f ${RUNNING_STATE}.lock ]]; do
        sleep .3
    done

    #
    # ... multi_mining_calc.sh ist mit den Berechnungen fertig, das Ergebnis ist in ${RUNNING_STATE}
    #
    if [ $verbose -eq 1 -o $debug -eq 1 ]; then
        echo $(date "+%Y-%m-%d %H:%M:%S" ) $(date +%s)
        echo "GPU #${gpu_idx}: Einlesen des NEUEN nun einzustellenden ${RUNNING_STATE} und erfahren, was GPU #${gpu_idx} zu tun hat..."
    fi
    # Da NUR die multi_mining_calc.sh diese Datei schreibt und da die Datei länger nicht mehr geschrieben wird,
    # brauchen wir sie hier auch nicht zum Lesen reservieren.
    # GLEICHZEITIGES LESEN SOLLTE KEIN PROBLEM DARSTELLEN.
    #_reserve_and_lock_file ${RUNNING_STATE}          # Zum Lesen reservieren...
    _read_in_actual_RUNNING_STATE                    # ... einlesen...
    #rm -f ${RUNNING_STATE}.lock                      # ... und wieder freigeben

    StartMiner=0
    [[ "${RunningGPUid[${gpu_uuid}]}" != "${gpu_idx}" ]] \
        && echo "Konsistenzcheck FEHLGESCHLAGEN!!! GPU-Idx aus RUNNING_STATE anders als er sein soll !!!"
    if [ ${#IamEnabled} -gt 0 ]; then
        echo "GPU #${gpu_idx}: Have to look whether to stop a miner and start another or let him run..."
        if [ ${IamEnabled} -eq 1 ]; then
            # echo "GPU #${gpu_idx}: Maybe something to stop first..."
            if [ "${WasItEnabled[${gpu_uuid}]}" == "1" ]; then
                if [ ${#RuningAlgo} -gt 0 ]; then
                    read algo miner_name miner_version muck888 <<<${RuningAlgo//#/ }
                    if [ "${RuningAlgo}" != "${WhatsRunning[${gpu_uuid}]}" ]; then

                        StopShell=${miner_name}_${miner_version}
                        printf "GPU #${gpu_idx}: STOPPING MinerShell ${StopShell}.sh with Algo ${algo}... "
                        if [ -f ${StopShell}.ppid ]; then
                            if [ -f ${StopShell}.pid ]; then
                                kill $(< ${StopShell}.ppid)
                                sleep $Erholung                                           # Damit sich die Karte "erholen" kann.
                                printf "done.\n"
                            else
                                printf "\nGPU #${gpu_idx}: OOOooops... Process ${StopShell}.sh ist weg. Möglicherweise hat er den Algo ${algo} DISABLED.\n"
                            fi
                        else
                            echo "OOOooops... MinerShell File ${StopShell}.ppid already gone. Das darf eigentlich nicht passieren!"
                        fi
                        rm -f ${StopShell}.ppid ${StopShell}.sh

                        # Evtl. ist eine neue MinerShell zu starten. Wenn ja, 1s Pause zur Erholung nach dem STOP
                        if [ ${#WhatsRunning[${gpu_uuid}]} -gt 0 ]; then
                            StartMiner=1
                        fi
                    else
                        if [ -f ${MinerShell}.ppid -a -f ${MinerShell}.pid ]; then
                            if [ "$(< ${MinerShell}.ppid)" != "$(< ${MinerShell}.pid)" ]; then
                                echo "--->INKONSISTENZ ENTDECKT: Alles deutet darauf, dass die MinerShell ${MinerShell}.sh noch läuft."
                                echo "--->Die Datei ${MinerShell}.ppid sowie ${MinerShell}.pid enthalten aber UNTERSCHIEDLICHE PIDs ???"
                                echo "--->Dem sollte bei Gelegenheit nachgegangen werden, weil das eigentlich nicht sein darf."
                            fi
                        fi
                        unset MinerShell_pid
                        if [ -f ${MinerShell}.ppid ]; then
                            MinerShell_pid=$(< ${MinerShell}.ppid)
                        elif [ -f ${MinerShell}.pid ]; then
                            MinerShell_pid=$(< ${MinerShell}.pid)
                            # Keine Datei ${MinerShell}.ppid mehr, sonst wäre er in diese Abfrage nicht rein gekommen
                            echo "--->INKONSISTENZ ENTDECKT: Alles deutet darauf, dass die MinerShell ${MinerShell}.sh noch laufen sollte."
                            echo "--->Trotzdem erklärt das nicht das Verschwinden der Datei ${MinerShell}.ppid und sollte erforscht werden."
                        fi
                        if [ ${#MinerShell_pid} -gt 0 ]; then
                            # Check, ob der Prozess tatsächlich noch existiert.
                            run_pid=$(ps -ef \
                                | gawk -e '$2 == '${MinerShell_pid}' && /'${gpu_uuid}'/ {pids=pids $2 " "} END {print pids}')
                            if [ ${run_pid} =~ ^${MinerShell_pid} ]; then
                                # Keinen Neustart fordern, denn die Shell läuft ja noch.
                                # Das haben wir eben auf Herz und Nieren überprüft.
                                # Und da der Prozess noch läuft, hat er sich auch den Algo noch nicht disabled un deshalb
                                # brauchen wir auch nicht die MINER_ALGO_DISABLED zu checken.
                                echo "GPU #${gpu_idx}: Miner ${miner_name} ${miner_version} with Algo ${algo} STILL RUNNING"
                            else
                                echo "--->INKONSISTENZ ENTDECKT: Alles deutet darauf, dass die MinerShell ${MinerShell}.sh noch laufen sollte."
                                echo "--->Datei ${MinerShell}.p?id ist auch noch da ($MinerShell_pid), aber der Prozess ist nicht mehr vorhanden ($run_pid)."
                                echo "--->Möglicherweise hat sich der Prozess wegen eines AlgoDisable oder fehlendem Internet selbst beendet."
                                echo "--->Sollte er in dem \"Disabled-GAP\" disabled worden sein, wird weiter unten der Start verhindert,"
                                echo "--->weil nochmal vor dem Start nachgesehen wird. Wir fordern hier also einfach einen Neustart."
                                # Wie das mit der abgebrochenen Internetverbindung ist, müssen wir später nochmal durchdenken.
                                # An dieser Stelle können wir sicher sagen, dass sich die MinerShell kurz nach dem Start selbst beendet
                                # OHNE den Miner zu starten, weil sie vor dem Miner-Start das Internet checkt.
                                # Und die ${MinerShell}.ppid müssen wir hier nicht löschen, da sie unten einfach überschrieben wird.
                                StartMiner=1
                            fi
                        else
                            echo "--->INKONSISTENZ ENTDECKT: Alles deutet darauf, dass die MinerShell ${MinerShell}.sh noch laufen sollte."
                            echo "--->Es gibt aber weder die Datei ${MinerShell}.ppid noch die Datei ${MinerShell}.pid mehr mit der PID."
                            echo "--->Möglicherweise hat sich der Prozess wegen eines AlgoDisable oder fehlendem Internet selbst beendet."
                            echo "--->Sollte er in dem \"Disabled-GAP\" disabled worden sein, wird weiter unten der Start verhindert,"
                            echo "--->weil nochmal vor dem Start nachgesehen wird. Wir fordern hier also einfach einen Neustart."
                            echo "--->Trotzdem erklärt das nicht das Verschwinden der Datei ${MinerShell}.ppid und sollte erforscht werden."
                            StartMiner=1
                        fi
                    fi
                else
                    echo "GPU #${gpu_idx}: Nothing ran, so nothing to stop, maybe something to start"
                    # Evtl. ist eine neue MinerShell zu starten.
                    if [ ${#WhatsRunning[${gpu_uuid}]} -gt 0 ]; then
                        StartMiner=1
                    fi
                fi
            else
                # GPU Vorher ENABLED, Jetzt DISABLED
                if [ ${#RuningAlgo} -gt 0 ]; then
                    read algo miner_name miner_version muck888 <<<${RuningAlgo//#/ }

                    StopShell=${miner_name}_${miner_version}
                    printf "GPU #${gpu_idx}: STOPPING MinerShell ${StopShell}.sh with Algo ${algo}, then DISABLED... "
                    if [ -f ${StopShell}.ppid ]; then
                        kill $(< ${StopShell}.ppid)
                        # sleep $Erholung wegen Erholung ist hier nicht nötig, weil nichts neues unmittelbar gestartet wird
                        printf "done.\n"
                    else
                        echo "OOOooops... MinerShell ${StopShell}.ppid already gone."
                    fi
                    rm -f ${StopShell}.ppid ${StopShell}.sh

                else
                    echo "GPU #${gpu_idx}: Nothing ran, so nothing to stop AND nothing to start because now DISABLED."
                fi
            fi
        else
            # GPU war im letzten Zyklus DISABLED
            if [ "${WasItEnabled[${gpu_uuid}]}" == "1" ]; then
                echo "GPU #${gpu_idx}: Was DISABLED, so nothing to stop, but maybe something to start..."
                if [ ${#WhatsRunning[${gpu_uuid}]} -gt 0 ]; then
                    StartMiner=1
                fi
            else
                echo "GPU #${gpu_idx}: Was DISABLED, so nothing to stop AND nothing to start because STILL DISABLED."
            fi
        fi
    else
        # Noch kein RUNNING_STATE da gewesen oder nicht enthalten gewesen
        # Bedeutet, dass kein Miner von hier gestartet gewesen sein sollte.
        # Müssen also auch auf nichts weiter achten als eventuell einen zu starten.
        if [ "${WasItEnabled[${gpu_uuid}]}" == "1" ]; then
            if [ ${#WhatsRunning[${gpu_uuid}]} -gt 0 ]; then
                StartMiner=1
            fi
        fi
    fi

    #############################################################################
    #############################################################################
    #
    #     Starten der MinerShell und Übergabe aller relevanten Parameter.
    #     Eine vorhandene Datei ${MinerShell}.ppid bedeutet:
    #          Laufende MinerShell und laufender Miner.
    #
    #############################################################################
    #############################################################################
    if [ ${StartMiner} -eq 1 ]; then
        algorithm=${WhatsRunning[${gpu_uuid}]}
        read algo miner_name miner_version muck888 <<<${algorithm//#/ }
        MinerShell=${miner_name}_${miner_version}

        # Ein letzter Blick in die MINER_ALGO_DISABLED Datei, weil der Algo während der Wartezeit von einem
        # laufenden Miner disabled geworden sein könnte und deshalb nicht mehr laufen darf.
        declare -i suddenly_disabled=0
        [[ -f ../MINER_ALGO_DISABLED ]] \
            && suddenly_disabled=$(grep -E -c -m1 -e "\b${algorithm}([^.\W]|$)" ../MINER_ALGO_DISABLED)
        if [ ${suddenly_disabled} -gt 0 ]; then
            echo "GPU #${gpu_idx}: MinerShell ${MinerShell}.sh sollte gestartet werden, IST ABER MITTLERWEILE DISABLED."
            echo "                 Dieses Disable kann nur in der Zeit geschehen sein, in der multi_mining_calc.sh gerechnet hat."
            echo "                 DAS DARF NICHT ZU OFT VORKOMMEN, SONST MUSS DAS NÄHER UTERSUCHT WERDEN!!!"
            rm -f ${MinerShell}.ppid
        else
            # Einschalten
            declare -n actInternalAlgos="Internal_${miner_name}_${miner_version//\./_}_Algos"
            InternalAlgoName=${actInternalAlgos[$algo]}
            algo_port=${PORTs[${algo}]}
            _setup_Nvidia_Default_Tuning_CmdStack
            cmdParameterString=""
            for cmd in "${CmdStack[@]}"; do
                cmdParameterString+="${cmd// /;} "
            done
        
            echo "GPU #${gpu_idx}: STARTE Miner Shell ${MinerShell}.sh und übergebe Algorithm ${algorithm} und mehr..."
            cp -f ../GPU-skeleton/MinerShell.sh ${MinerShell}.sh
            ./${MinerShell}.sh \
              ${algorithm}        \
              ${gpu_idx}          \
              "SelbstWahl"        \
              ${algo_port}        \
              "1060"              \
              ${InternalAlgoName} \
              ${gpu_uuid}         \
              $cmdParameterString \
              >>${MinerShell}.log &
            echo $! >${MinerShell}.ppid
        fi
    fi

    #############################################################################
    #
    #
    # Warten auf neue aktuelle Daten aus dem Web, die durch
    #        algo_multi_abfrage.sh
    # beschafft werden müssen und deren Gültigkeit sichergestellt werden muss!
    #
    #
    #
    #     ###WARTET### jetzt, bis das "Alter" der Datei ${SYNCFILE} aktueller ist als ${new_Data_available}
    #                         mit der Meldung "Waiting for new actual Pricing Data from the Web..."
    echo $(date "+%Y-%m-%d %H:%M:%S" ) $(date +%s)
    echo "GPU #${gpu_idx}: Waiting for new actual Pricing Data from the Web..."
    while [ "${new_Data_available}" == "$(date --utc --reference=${SYNCFILE} +%s)" ] ; do
        sleep .5
    done
    #  9. Merkt sich das neue "Alter" von ${SYNCFILE} in der Variablen ${new_Data_available}
    new_Data_available=$(date --utc --reference=${SYNCFILE} +%s)
    
done
