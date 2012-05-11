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



#define NETWORK_SOCKET 1
#define FILE_SOCKET 2

#define STREAM 1

#define STDIN_BUFFER 8
#define STDOUT_BUFFER 8

@interface libServerSocket : NSObject

int createListenSocket(int domain, int type, int port);
	/*
	 * return:
	 * 		-10 : failed to create socket
	 * 		-20 : failed to bind address to socket
	 * 		> 0 : socket descriptor
	 * */

int createConnectionSocket(int listeningSocket);
	/*
	 *	return:
	 *		 <0 : failed
	 *		 >0 : socket descriptor	
	 */

@end
