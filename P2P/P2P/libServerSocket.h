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
