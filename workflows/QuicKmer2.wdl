version 1.0

workflow quicKmer2_POC {
    input {
    File pathToInput
    File pathToReference
    File pathToQRef
    File pathToQRef_bed
    File pathToQRef_qgc
    File pathToQRef_controlbed
    File pathToQRef_qm
    File pathToReference_fai
    File pathToInput_crai
    String sample
    }
    call quicKmer2 {
        input:
            pathToInput=pathToInput,
            pathToReference=pathToReference,
            pathToQRef=pathToQRef,
            pathToQRef_bed=pathToQRef_bed,
            pathToQRef_qgc=pathToQRef_qgc,
            pathToReference_fai=pathToReference_fai,
            pathToInput_crai=pathToInput_crai,
            pathToQRef_controlbed=pathToQRef_controlbed,
            pathToQRef_qm=pathToQRef_qm,
            sample=sample          
    }

}

task quicKmer2{
    input{
    File pathToInput
    File pathToReference
    File pathToQRef
    File pathToQRef_bed
    File pathToQRef_qgc
    File pathToReference_fai
    File pathToInput_crai 
    File pathToQRef_controlbed
    File pathToQRef_qm
    String sample
    }
    Int disk_size = ceil(size(pathToInput,"GB")+57+size(pathToReference)+6)
    command <<<
        set -euo pipefail
        mkdir -p out
        export PATH=/opt/conda/bin:$PATH
        export PATH=/QuicK-mer2:$PATH
        /opt/conda/bin/samtools view -F 3840 -T ~{pathToReference} --input-fmt-option required_fields=0x202 ~{pathToInput} | awk '{print ">\n"$10}' | /QuicK-mer2/quicKmer2 count -t 6 ~{pathToQRef} /dev/fd/0 out/~{sample}.qm2
        echo "Finished count!"
        /QuicK-mer2/quicKmer2 est ~{pathToQRef} out/~{sample}.qm2 out/~{sample}.qm2.CN.1k.bed
        grep -v decoy out/~{sample}.qm2.CN.1k.bed | grep -v chrEBV > out/~{sample}.qm2.CN.1k.bed.browser
        /QuicK-mer2/make-colortrack-fordisplay.py --cn out/~{sample}.qm2.CN.1k.bed.browser --name ~{sample}
        rm out/~{sample}.qm2.bin         
        /opt/conda/bin/bgzip out/~{sample}.qm2.CN.1k.bed.browser
        /opt/conda/bin/bgzip out/~{sample}.qm2.CN.1k.bed
        /opt/conda/bin/bgzip out/~{sample}.qm2.CN.1k.bed.browser.bedColor
        /opt/conda/bin/tabix -p bed out/~{sample}.qm2.CN.1k.bed.gz
        /opt/conda/bin/bgzip out/~{sample}.qm2.txt
    >>>
    runtime {
        docker: "jng2/testme:qm_CN"
        memory: "64G"
        cpu: "6"
        disks: "local-disk "+ disk_size+" SSD"
        
        
    }
    output {
        File bedFile="out/~{sample}.qm2.CN.1k.bed.gz"
        File bedBroswer="out/~{sample}.qm2.CN.1k.bed.browser.gz"
        File bedColor="out/~{sample}.qm2.CN.1k.bed.browser.bedColor.gz"
        File qmTxt="out/~{sample}.qm2.txt.gz"
        File bed_tabix="out/~{sample}.qm2.CN.1k.bed.gz.tbi"
        File png="out/~{sample}.qm2.png"
    }
}
