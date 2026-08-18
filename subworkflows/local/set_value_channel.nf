//
// Check input samplesheet and get read channels
//

include { GUNZIP } from '../../modules/nf-core/gunzip/main'

workflow SET_VALUE_CHANNEL {
    take:
    infile // file: path to compressed or not fasta/gtf

    main:
    if (infile =~ /.gz$/) {
        GUNZIP([[], file(infile)])
    }

    emit:
    data = infile =~ /.gz$/ ? GUNZIP.out.gunzip.map { pair -> pair[1] } : channel.value(file(infile))
}
