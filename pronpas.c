/*
 Copyright (c) 2009, Stefan Lange-Hegermann
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of source.bricks nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY STEFAN LANGE-HEGERMANN ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL STEFAN LANGE-HEGERMANN BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "pronpas.h"
#include "trigramen.h"
#include "math.h"
#include "stdlib.h"
#include <sys/types.h>
#include <sys/time.h>

void seedPWD() {
	struct timezone tz;
	struct timeval systime;
	
	gettimeofday (&systime, &tz);
	srand48 (systime.tv_usec);
}

char *getPWD(int password_length) {
    int c1, c2, c3;		/* array indices */
    long sumfreq;		/* total frequencies[c1][c2][*] */
    double pik;			/* raw random number in [0.1] from drand48() */
    long ranno;			/* random number in [0,sumfreq] */
    long sum;			/* running total of frequencies */
    char *password=malloc(password_length+1);		/* buffer to develop a password */
    int nchar;			/* number of chars in password so far */

	pik = drand48 ();	/* random number [0,1] */
	sumfreq = sigma;	/* sigma calculated by loadtris */
	ranno = (long)(pik * sumfreq); /* Weight by sum of frequencies. */
	sum = 0;
	for (c1=0; c1 < 26; c1++) {
	    for (c2=0; c2 < 26; c2++) {
		for (c3=0; c3 < 26; c3++) {
		    sum += tris[c1][c2][c3];
		    if (sum > ranno) { /* Pick first value */
			password[0] = 'a' + c1;
			password[1] = 'a' + c2;
			password[2] = 'a' + c3;
			c1 = c2 = c3 = 26; /* Break all loops. */
		    } /* if sum */
		} /* for c3 */
	    } /* for c2 */
	} /* for c1 */

	/* Do a random walk. */
	nchar = 3;		/* We have three chars so far. */
	while (nchar < password_length) {
	    password[nchar] = '\0';
	    password[nchar+1] = '\0';
	    c1 = password[nchar-2] - 'a'; /* Take the last 2 chars */
	    c2 = password[nchar-1] - 'a'; /* .. and find the next one. */
	    sumfreq = 0;
	    for (c3=0; c3 < 26; c3++)
		sumfreq += tris[c1][c2][c3];
	    /* Note that sum < duos[c1][c2] because
	       duos counts all digraphs, not just those
	       in a trigraph. We want sum. */
	    if (sumfreq == 0) { /* If there is no possible extension.. */
		break;	/* Break while nchar loop & print what we have. */
	    }
	    /* Choose a continuation. */
	    pik = drand48 ();
	    ranno = (long)(pik * sumfreq); /* Weight by sum of frequencies for row. */
	    sum = 0;
	    for (c3=0; c3 < 26; c3++) {
		sum += tris[c1][c2][c3];
		if (sum > ranno) {
		    password[nchar++] = 'a' + c3;
		    c3 = 26;	/* Break the for c3 loop. */
		}
	    } /* for c3 */
	} /* while nchar */
	return password;
}