/*
 P2P is an academical application. It is a peer to peer fileshareing program.
 
 Copyright (C) 2012	Jordi Bueno Dominguez, Jordi Chulia Benlloch, Pau Sastre Miguel
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */



#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h> //needed for socket.h and in.h
#include <sys/socket.h>
#include <netinet/in.h> //internet domain stuff
#include <netdb.h> //server info
#include <string.h> //provides bzero
#include <strings.h> //provides strlen

#include "libServerSocket.h"

/*
 * Domain:
 * #define NETWORK_SOCKET 1
 * #define FILE_SOCKET 2
 *
 * socket type:
 * #define STREAM 1
 * */

@implementation libServerSocket

int createListenSocket(int domain, int type, int port)
	/*
	 * Will return the identifier of the listen socket
	 * */
{
	int domainSocket;
	switch(domain)
	{
		case 2:
			domainSocket = AF_UNIX;
			break;
		default:
		case 1:
			domainSocket = AF_INET;
			break;
	}

	int typeSocket;
	switch(type)
	{
		default:
		case 1:
			typeSocket = SOCK_STREAM;
			break;
	}

	int socketDescriptor = socket(domainSocket, typeSocket, 0);
	if(socketDescriptor < 0) return -10; //failed to create socket

	struct sockaddr_in serverAddress;
	bzero((char *) &serverAddress, sizeof(serverAddress));

	serverAddress.sin_family = domainSocket;
	serverAddress.sin_port = htons(port);
	serverAddress.sin_addr.s_addr = INADDR_ANY; //local ip

	int binded = bind(socketDescriptor, (struct sockaddr *) &serverAddress, sizeof(serverAddress));
	if (binded < 0) return -20; //failed to bind address to socket

	listen(socketDescriptor, 5);

	return socketDescriptor;
}

int createConnectionSocket(int listeningSocket)
	/*
	 * Will wait until a connection is created
	 * */
{
	int connectionSocket;
	socklen_t clientAddressSize;
	struct sockaddr_in clientAddress;

	clientAddressSize = sizeof(clientAddress);
	connectionSocket = accept(listeningSocket, (struct sockaddr *) &clientAddress, &clientAddressSize);

	return connectionSocket;
}

@end
