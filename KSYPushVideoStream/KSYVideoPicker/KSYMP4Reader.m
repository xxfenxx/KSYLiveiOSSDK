//
//  KSYMP4Reader.m
//  protos
//
//  Created by Blues on 10/11/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import "KSYMP4Reader.h"
#import "KSYMP4Atom.h"
#import "KSYMP4Frame.h"
#import "KSYMP4Descriptor.h"
#import "KSYMP4Record.h"
#import "KSYBytesData.h"

@interface KSYMP4Reader () {
    int tracks;
    int scale;
}

@property (atomic, retain) NSData *buf;

/**
 @abstract
 This handles the moov atom being at the beginning or end of the file, so
 the mdat may also be before or after the moov atom.
 */
- (void)decodeHeader:(KSYBytesData *)data;
- (int64_t)decodeNoMoovHeader:(KSYBytesData *)data;
- (void)readMoov:(KSYMP4Atom *)moov;
- (void)readMdia:(KSYMP4Atom *)mdia;
- (void)readMinf:(KSYMP4Atom *)minf;
- (void)readSmhd:(KSYMP4Atom *)smhd;
- (void)readStbl:(KSYMP4Atom *)stbl video:(BOOL)video;
- (void)readStsd:(KSYMP4Atom *)stsd;
- (void)readStsc:(KSYMP4Atom *)stsc video:(BOOL)video;
- (void)readStts:(KSYMP4Atom *)stts;
- (void)readEsds:(KSYMP4Atom *)esds;
- (void)readVmhd:(KSYMP4Atom *)vmhd;
- (void)readAvc1:(KSYMP4Atom *)avc1;
- (void)readAvcC:(KSYMP4Atom *)avcc;
- (void)readStco:(KSYMP4Atom *)stco video:(BOOL)video;
- (void)readStsz:(KSYMP4Atom *)stco video:(BOOL)video;
- (void)readHdlr:(KSYMP4Atom *)hdlr;

@end

@implementation KSYMP4Reader

@synthesize buf;
@synthesize mdatOffset;
@synthesize moovOffset;
@synthesize audioDecoderBytes;
@synthesize videoDecoderBytes;
@synthesize avcLevel;
@synthesize avcProfile;
@synthesize width;
@synthesize height;
@synthesize audioCodecId;
@synthesize videoCodecId;
@synthesize audioTimeScale;
@synthesize audioChannels;
@synthesize audioCodecType;
@synthesize audioSamplesToChunks;
@synthesize videoSamplesToChunks;
@synthesize videoChunkOffsets;
@synthesize videoSampleDuration;
@synthesize videoTimeScale;
@synthesize hasAudio;
@synthesize hasVideo;
@synthesize syncSamples;
@synthesize videoSamples;
@synthesize frames;
@synthesize videoSampleCount;
@synthesize audioChunkOffsets;
@synthesize audioSampleDuration;
@synthesize audioSamples;
@synthesize compositionTimes;

- (id)init {
    self = [super init];
    if (self) {
        audioCodecType = 1;
        videoSampleDuration = 125;
        audioSampleDuration = 1024;
        scale = 0;
    }
    return self;
}

- (void)dealloc {
    
}

- (void)readData:(KSYBytesData *)data {
    [self decodeHeader:data];
}

- (void)decodeHeader:(KSYBytesData *)data {
    // the first atom will/should be the type
    KSYMP4Atom *type = [KSYMP4Atom createAtomFromData:data];
    // We're expecting ftyp
    NSLog(@"%@", [KSYMP4Atom intToType:type.type]);
    if ([[KSYMP4Atom intToType:type.type] caseInsensitiveCompare:@"ftyp"] != 0) {
        // It's not head part. Cannot decode header then
        return;
    }
    
    int topAtoms = 0;
    // We want a moov and an mdat, anything else throw the invalid file type error
    while (topAtoms < 2 && data.position + 4 <= [data length]) {
        KSYMP4Atom *atom = [KSYMP4Atom createAtomFromData:data];
        if (!atom) {
            // invalid data packet.. either return or do something
            break;
        }
        
        KSYMP4Atom *moov;
        KSYMP4Atom *mdat;
        switch (atom.type) {
            case MKBETAG('m', 'o', 'o', 'v'):
                topAtoms++;
                
                moov = atom;
                NSLog(@"Type %@", [KSYMP4Atom intToType:moov.type]);
                NSLog(@"moov children: %d", moov.children.count);
                moovOffset = [data length] - (long)moov.size;
                [self readMoov:moov];
                break;
                
            case MKBETAG('m', 'd', 'a', 't'):
                topAtoms++;
                
                mdat = atom;
                // int64_t dataSize = mdat.size;
                NSLog(@"mdat size: %lld, position: %d", mdat.size, [data position]);
                mdatOffset = [data length] - (long)mdat.size;
                break;
                
            case MKBETAG('f', 'r', 'e', 'e'):
            case MKBETAG('w', 'i', 'd', 'e'):
                break;
                
            default:
                NSLog(@"unexpected atom: %@", [KSYMP4Atom intToType:atom.type]);
        }
    }
}

- (NSArray *)readFrames:(KSYBytesData *)data {
    long offset = 0;
    NSMutableArray *newFrames = [[NSMutableArray alloc] init];
    [data reset];
    
    if (mdatOffset <= 0) {
        mdatOffset = [self decodeNoMoovHeader:data];
        offset += mdatOffset;
    }
    
    NSUInteger dataSize = [data length];
    while (dataSize - [data position] >= 5) {
        int frameSize = (int)[data getInt32];
        char objectType = [data getInt8];
        
        if (mdatOffset + frameSize + offset > dataSize) {
            break;
        }
        
        KSYMP4Frame *frame = [[KSYMP4Frame alloc] init];
        frame.type = objectType;
        frame.size = frameSize;
        frame.offset = offset;
        [newFrames addObject:frame];
        
        offset += frameSize + 4;
        [data skip:frameSize - 1];
    }
    self.frames = newFrames;
    return frames;
}

- (int64_t)decodeNoMoovHeader:(KSYBytesData *)data {
    // the first atom will/should be the type
    KSYMP4Atom *type = [KSYMP4Atom createAtomFromData:data];
    // We're expecting ftyp
    NSLog(@"%@", [KSYMP4Atom intToType:type.type]);
    if ([[KSYMP4Atom intToType:type.type] caseInsensitiveCompare:@"ftyp"] != 0) {
        // It's not head part. Cannot decode header then
        return 0;
    }
    
    BOOL foundMdat = NO;
    int64_t offset = 0;
    
    // We want a moov and an mdat, anything else throw the invalid file type error
    while (!foundMdat && data.position + 4 <= [data length]) {
        KSYMP4Atom *atom = [KSYMP4Atom createAtomFromData:data];
        if (!atom) {
            // invalid data packet.. either return or do something
            break;
        }
        
        switch (atom.type) {
            case MKBETAG('m', 'd', 'a', 't'): {
                offset = data.position - atom.size;
                NSLog(@"mdat offset %lld", offset);
                foundMdat = YES;
                break;
            }
                
            default:
                NSLog(@"unexpected atom: %@", [KSYMP4Atom intToType:atom.type]);
        }
    }
    
    return offset;
}

- (void)readMdia:(KSYMP4Atom *)mdia {
    // mdia: mdhd, hdlr, minf
    // get the media header atom
    KSYMP4Atom *mdhd = [mdia lookup:MKBETAG('m', 'd', 'h', 'd') number:0];
    if (mdhd) {
        NSLog(@"Media data header atom found");
        //this will be for either video or audio depending media info
        scale = mdhd.timeScale;
        NSLog(@"Time scale %d", scale);
    }
    
    KSYMP4Atom *hdlr = [mdia lookup:MKBETAG('h', 'd', 'l', 'r') number:0];
    if (hdlr) {
        [self readHdlr:hdlr];
    }
    
    // get the media header atom
    KSYMP4Atom *minf = [mdia lookup:MKBETAG('m', 'i', 'n', 'f') number:0];
    if (minf != nil) {
        NSLog(@"Media info atom found");
        [self readMinf:minf];
    }
}

- (void)readMinf:(KSYMP4Atom *)minf {
    // minf: (audio) smhd, dinf, stbl / (video) vmhd,
    // dinf, stbl
    KSYMP4Atom *smhd = [minf lookup:MKBETAG('s', 'm', 'h', 'd') number:0];
    if (smhd != nil) {
        NSLog(@"Sound header atom found");
        [self readSmhd:smhd];
    }
    KSYMP4Atom *vmhd = [minf lookup:MKBETAG('v', 'm', 'h', 'd') number:0];
    if (vmhd != nil) {
        NSLog(@"Video header atom found");
        [self readSmhd:smhd];
    }
    KSYMP4Atom *stbl = [minf lookup:MKBETAG('s', 't', 'b', 'l') number:0];
    if (stbl != nil) {
        NSLog(@"Sample table atom found");
        // stbl: stsd, stts, stss, stsc, stsz, stco,
        // stsh
        NSLog(@"Sound stbl children: %d", stbl.children.count);
        // stsd - sample description
        // stts - time to sample
        // stsc - sample to chunk
        // stsz - sample size
        // stco - chunk offset
        [self readStbl:stbl video:vmhd != nil];
    }
}

- (void)readSmhd:(KSYMP4Atom *)smhd {
    
}

- (void)readStts:(KSYMP4Atom *)stts {
    
}

- (void)readStbl:(KSYMP4Atom *)stbl video:(BOOL)video  {
    // stsd - has codec child
    KSYMP4Atom *stsd = [stbl lookup:MKBETAG('s', 't', 's', 'd') number:0];
    if (stsd != nil) {
        [self readStsd:stsd];
    }
    
    // stsc - has records
    KSYMP4Atom *stsc = [stbl lookup:MKBETAG('s', 't', 's', 'c') number:0];
    if (stsc) {
        [self readStsc:stsc video:video];
    }
    
    // stco - has Chunks
    KSYMP4Atom *stco = [stbl lookup:MKBETAG('s', 't', 'c', 'o') number:0];
    if (stco) {
        [self readStco:stco video:video];
    }
    
    // stss - has Sync - no sync means all samples are keyframes
    KSYMP4Atom *stss = [stbl lookup:MKBETAG('s', 't', 's', 's') number:0];
    if (stss) {
        NSLog(@"Sync sample atom found");
        //vector full of integers
        self.syncSamples = stss.syncSamples;
        NSLog(@"Keyframes: %d", syncSamples.count);
    }
    
    // stsz - has Samples
    KSYMP4Atom *stsz = [stbl lookup:MKBETAG('s', 't', 's', 'z') number:0];
    if (stsz) {
        [self readStsz:stsz video:video];
    }
    
    // stts - has TimeSampleRecords
    KSYMP4Atom *stts = [stbl lookup:MKBETAG('s', 't', 't', 's') number:0];
    if (stts) {
        NSLog(@"Time to sample atom found");
        NSArray *records = stts.timeToSamplesRecords;
        NSLog(@"Record count: %d", records.count);
        MP4TimeSampleRecord *r = [records objectAtIndex:0];
        NSLog(@"Record data: Consecutive samples=%d Duration=%d",
              r.consecutiveSamples, r.sampleDuration);
        if (video) {
            // if we have 1 record then all samples have the same duration
            if (records.count > 1) {
                NSLog(@"Video samples have differing durations, video playback may fail");
            }
            videoSampleDuration = r.sampleDuration;
        } else {
            // if we have 1 record then all samples have the same duration
            if (records.count > 1) {
                NSLog(@"Audio samples have differing durations, audio playback may fail");
            }
            audioSampleDuration = r.sampleDuration;
        }
    }
    
    // ctts - (composition) time to sample
    KSYMP4Atom *ctts = [stbl lookup:MKBETAG('c', 't', 't', 's') number:0];
    if (ctts) {
        NSLog(@"Time to sample atom found");
        self.compositionTimes = ctts.comptimeToSamplesRecords;
        NSLog(@"Record count: %d", compositionTimes.count);
    }
}

- (void)readStsz:(KSYMP4Atom *)stsz video:(BOOL)video {
    NSLog(@"Sample size atom found");
    if (video) {
        self.videoSamples = stsz.samples;
        videoSampleCount = videoSamples.count;
        // If sample size is 0 then the table must be checked due
        // to variable sample sizes
        NSLog(@"Sample video count: %d", videoSampleCount);
    } else {
        self.audioSamples = stsz.samples;
        NSLog(@"Sample audio count: %d", audioSamples.count);
    }
    NSLog(@"Sample size: %d", stsz.samples.count);
}

- (void)readStco:(KSYMP4Atom *)stco video:(BOOL)video {
    NSLog(@"Chunk offset atom found");
    if (video) {
        self.videoChunkOffsets = stco.chunks;
    } else {
        self.audioChunkOffsets = stco.chunks;
    }
    
    NSLog(@"Chunk count: %d", videoChunkOffsets.count);
}

- (void)readStsc:(KSYMP4Atom *)stsc video:(BOOL)video {
    NSLog(@"Sample to chunk atom found");
    if (video) {
        self.videoSamplesToChunks = stsc.records;
        NSLog(@"Record count: %d", videoSamplesToChunks.count);
        if (videoSamplesToChunks.count > 0) {
            KSYMP4Record *rec = [videoSamplesToChunks objectAtIndex:0];
            NSLog(@"Record data: Description index=%d Samples per chunk=%d",
                  rec.sampleDescription, rec.samplePerChunk);
        }
    } else {
        self.audioSamplesToChunks = stsc.records;
        NSLog(@"Record count: %d", audioSamplesToChunks.count);
        if (audioSamplesToChunks.count > 0) {
            KSYMP4Record *rec = [audioSamplesToChunks objectAtIndex:0];
            NSLog(@"Record data: Description index=%d Samples per chunk=%d",
                  rec.sampleDescription, rec.samplePerChunk);
        }
    }
}

- (void)readStsd:(KSYMP4Atom *)stsd {
    // stsd: mp4a
    NSLog(@"Sample description atom found, containing %d children",
          stsd.children.count);
    KSYMP4Atom *mp4a = [stsd lookup:MKBETAG('m', 'p', '4', 'a') number:0];
    if (mp4a) {
        NSLog(@"MP4 audio atom found, containing %d children", mp4a.children.count);
        
        // could set the audio codec here
        self.audioCodecId = [KSYMP4Atom intToType:mp4a.type];
        NSLog(@"Sample size: %d", mp4a.sampleSize);
        
        int ats = mp4a.timeScale;
        // skip invalid audio time scale
        if (ats > 0) {
            audioTimeScale = ats * 1.0;
        }
        audioChannels = mp4a.channelCount;
        NSLog(@"Sample rate (audio time scale): %f", audioTimeScale);
        NSLog(@"Channels: %d", audioChannels);
        
        // look for esds
        KSYMP4Atom *esds = [mp4a lookup:MKBETAG('e', 's', 'd', 's') number:0];
        if (esds != nil) {
            [self readEsds:esds];
        }
    }
    
    // stsd - has codec child
    KSYMP4Atom *avc1 = [stsd lookup:MKBETAG('a', 'v', 'c', '1') number:0];
    if (avc1 != nil) {
        [self readAvc1:avc1];
    }
}

- (void)readEsds:(KSYMP4Atom *)esds {
    NSLog(@"Elementary stream descriptor atom found, containing %d children", esds.children.count);
    KSYMP4Descriptor *descriptor = esds.esdDescriptor;
    if (descriptor != nil) {
        for (KSYMP4Descriptor *descr in descriptor.children) {
            if (descr.children.count > 0) {
                for (KSYMP4Descriptor *descr2 in descr.children) {
                    // http://stackoverflow.com/questions/3987850/mp4-atom-how-to-discriminate-the-audio-codec-is-it-aac-or-mp3
                    if (descr2.type == kMP4DecSpecificInfoDescriptorTag) {
                        // we only want the MP4DecSpecificInfoDescriptorTag
                        self.audioDecoderBytes = descr2.dsID;
                        /* the first 5 (0-4) bits tell us about the coder used for aacaot/aottype
                         * http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio
                         0 - NULL
                         1 - AAC Main (a deprecated AAC profile from MPEG-2)
                         2 - AAC LC or backwards compatible HE-AAC
                         3 - AAC Scalable Sample Rate
                         4 - AAC LTP (a replacement for AAC Main, rarely used)
                         5 - HE-AAC explicitly signaled (Non-backward compatible)
                         23 - Low Delay AAC
                         29 - HE-AACv2 explicitly signaled
                         32 - MP3on4 Layer 1
                         33 - MP3on4 Layer 2
                         34 - MP3on4 Layer 3
                         */
                        Byte audioCoderType =
                        [[KSYBytesData dataWithNSData:audioDecoderBytes] getInt8];
                        // match first byte
                        switch (audioCoderType) {
                            case 0x02:
                                NSLog(@"Audio type AAC LC");
                            case 0x11: //ER (Error Resilient) AAC LC
                                NSLog(@"Audio type ER AAC LC");
                            default:
                                audioCodecType = 1; //AAC LC
                                break;
                            case 0x01:
                                NSLog(@"Audio type AAC Main");
                                audioCodecType = 0; //AAC Main
                                break;
                            case 0x03:
                                NSLog(@"Audio type AAC SBR");
                                audioCodecType = 2; //AAC LC SBR
                                break;
                            case 0x05:
                            case 0x1d:
                                NSLog(@"Audio type AAC HE");
                                audioCodecType = 3; //AAC HE
                                break;
                            case 0x20:
                            case 0x21:
                            case 0x22:
                                NSLog(@"Audio type MP3");
                                audioCodecType = 33; //MP3
                                self.audioCodecId = @"mp3";
                                break;
                        }
                        // we want to break out of top level for loop
                        break;
                    }
                }
            }
        }
    }
}

- (void)readVmhd:(KSYMP4Atom *)vmhd {
    
}

- (void)readAvc1:(KSYMP4Atom *)avc1 {
    NSLog(@"AVC1 children: %d", avc1.children.count);
    // set the video codec here - may be avc1 or mp4v
    self.videoCodecId = [KSYMP4Atom intToType:avc1.type];
    
    // video decoder config
    KSYMP4Atom *avcC = [avc1 lookup:MKBETAG('a', 'v', 'c', 'C') number:0];
    if (avcC != nil) {
        [self readAvcC:avcC];
    } else {
        // quicktime and ipods use a pixel aspect atom
        // since we have no avcC check for this and avcC may
        // be a child
        KSYMP4Atom *pasp = [avc1 lookup:MKBETAG('p', 'a', 's', 'p') number:0];
        if (pasp != nil) {
            NSLog(@"PASP children: %d", pasp.children.count);
            avcC = [pasp lookup:MKBETAG('a', 'v', 'c', 'C') number:0];
            if (avcC != nil) {
                [self readAvcC:avcC];
            }
        }
    }
}

- (void)readAvcC:(KSYMP4Atom *)avcc {
    avcLevel = avcc.avcLevel;
    NSLog(@"AVC level: %d", avcLevel);
    avcProfile = avcc.avcProfile;
    NSLog(@"AVC Profile: %d", avcProfile);
    NSLog(@"AVCC size: %d", avcc.children.count);
    
    self.videoDecoderBytes = avcc.videoConfigBytes;
}

- (void)readMoov:(KSYMP4Atom *)moov {
    KSYMP4Atom *mvhd = [moov lookup:MKBETAG('m', 'v', 'h', 'd') number:0];
    if (mvhd) {
        //
    }
    
    // We would like to have two tracks, but it shouldn't be a requirement
    int loops = 0;
    tracks = 0;
    do {
        KSYMP4Atom *trak = [moov lookup:MKBETAG('t', 'r', 'a', 'k') number:loops];
        if (trak) {
            NSLog(@"Track atom found");
            NSLog(@"trak children: %d", trak.children.count);
            
            KSYMP4Atom *mdia = [trak lookup:MKBETAG('m', 'd', 'i', 'a') number:0];
            if (mdia) {
                NSLog(@"Media atom found");
                [self readMdia:mdia];
            }
            
            tracks++;
        }
        loops++;
    } while (loops < 3);
}

- (void)readHdlr:(KSYMP4Atom *)hdlr {
    NSLog(@"Handler ref atom found");
    // soun or vide
    NSString *hdlrType = [KSYMP4Atom intToType:hdlr.handlerType];
    NSLog(@"Handler type: %@", hdlrType);
    if ([hdlrType compare:@"vide"] == 0) {
        hasVideo = true;
        if (scale > 0) {
            videoTimeScale = scale * 1.0;
            NSLog(@"Video time scale: %f", videoTimeScale);
        }
    } else if ([hdlrType compare:@"soun"] == 0) {
        hasAudio = true;
        if (scale > 0) {
            audioTimeScale = scale * 1.0;
            NSLog(@"Audio time scale: %f", audioTimeScale);
        }
    }
    tracks++;
}

- (NSArray *)readFrames {
    // position
    int pos;
    int sample = 1;
    int i = 0;
    
    NSMutableArray *newFrames = [[NSMutableArray alloc] init];
    // audioSamplesToChunks = nil;
    
    // if audio-only, skip this
    if (videoSamplesToChunks) {
        // handle composite times
        int compositeIndex = 0;
        int compositeTimeIndex = 0;
        MP4CompositionTimeSampleRecord *compositeTimeEntry = nil;
        if (compositionTimes != nil && compositionTimes.count > compositeTimeIndex) {
            compositeTimeEntry = [compositionTimes objectAtIndex:compositeTimeIndex++];
        }
        for (KSYMP4Record *record in videoSamplesToChunks) {
            int firstChunk = record.firstChunk;
            int lastChunk = videoChunkOffsets.count;
            if (i < videoSamplesToChunks.count - 1) {
                KSYMP4Record *nextRecord = [videoSamplesToChunks objectAtIndex:i + 1];
                lastChunk = nextRecord.firstChunk - 1;
            }
            i++;
            for (int chunk = firstChunk; chunk <= lastChunk; chunk++) {
                int sampleCount = record.samplePerChunk;
                pos = [[videoChunkOffsets objectAtIndex:chunk - 1] integerValue];
                while (sampleCount > 0) {
                    // Calculate ts
                    double ts = (videoSampleDuration * (sample - 1)) / videoTimeScale;
                    // Check to see if the sample is a keyframe
                    BOOL keyframe = NO;
                    // Some files appear not to have sync samples
                    if (syncSamples != nil) {
                        keyframe = [syncSamples containsObject:[NSNumber numberWithInt:sample]];
                        /*
                         if (seekPoints == nil) {
                         seekPoints = new LinkedList<Integer>();
                         }
                         int keyframeTs = (int) Math.round(ts * 1000.0);
                         seekPoints.add(keyframeTs);
                         timePosMap.put(keyframeTs, pos);
                         */
                    }
                    // Size of the sample
                    int size = [[videoSamples objectAtIndex:(sample - 1)] integerValue];
                    
                    // Create a frame
                    KSYMP4Frame *frame = [[KSYMP4Frame alloc] init];
                    frame.keyFrame = keyframe;
                    frame.offset = pos;
                    frame.size = size;
                    frame.timestamp = ts;
                    frame.type = kFrameTypeVideo;
                    
                    // Set time offset value from composition records
                    if (compositeTimeEntry) {
                        // How many samples have this offset
                        int consecutiveSamples = compositeTimeEntry.consecutiveSamples;
                        frame.timeOffset = compositeTimeEntry.sampleOffset;
                        // Increment our count
                        compositeIndex++;
                        if (compositeIndex - consecutiveSamples == 0) {
                            // Ensure there are still times available
                            if (compositionTimes.count > compositeTimeIndex) {
                                // Get the next one
                                compositeTimeEntry = [compositionTimes objectAtIndex:compositeTimeIndex++];
                            }
                            // Reset
                            compositeIndex = 0;
                        }
                    }
                    
                    // Add the frame
                    [newFrames addObject:frame];
                    
                    // Increase and decrease stuff
                    pos += size;
                    sampleCount--;
                    sample++;
                }
            }
        }
    }
    
    if (audioSamplesToChunks) {
        //add the audio frames / samples / chunks
        sample = 1;
        for (KSYMP4Record *record in audioSamplesToChunks) {
            int firstChunk = record.firstChunk;
            int lastChunk = audioChunkOffsets.count;
            if (i < audioSamplesToChunks.count - 1) {
                KSYMP4Record *nextRecord = [audioSamplesToChunks objectAtIndex:(i + 1)];
                lastChunk = nextRecord.firstChunk - 1;
            }
            for (int chunk = firstChunk; chunk <= lastChunk; chunk++) {
                int sampleCount = record.samplePerChunk;
                pos = [[audioChunkOffsets objectAtIndex:chunk - 1] integerValue];
                while (sampleCount > 0 && sample <= audioSamples.count) {
                    // calculate ts
                    double ts = (audioSampleDuration * (sample - 1)) / audioTimeScale;
                    // sample size
                    int size = [[audioSamples objectAtIndex:(sample - 1)] integerValue];
                    // create a frame
                    KSYMP4Frame *frame = [[KSYMP4Frame alloc] init];
                    frame.offset = pos;
                    frame.size = size;
                    frame.timestamp = ts;
                    frame.type = kFrameTypeAudio;
                    
                    // add the frame
                    [newFrames addObject:frame];
                    
                    // inc and dec stuff
                    pos += size;
                    sampleCount--;
                    sample++;
                }
            }
        }
    }
    
    self.frames = [newFrames sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(KSYMP4Frame *)obj1 compareMP4Frame:(KSYMP4Frame *)obj2];
    }];
    return frames;
}


@end
