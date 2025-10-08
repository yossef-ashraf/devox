# Apache Benchmark (`ab`)

## Overview
Apache Benchmark (`ab`) is a command-line tool used for testing the performance of HTTP servers. It allows users to measure how many requests per second a server can handle and analyze response times under various loads.

## Features
- Simulates multiple concurrent users making requests to a web server.
- Measures server response times and throughput.
- Provides detailed performance statistics.
- Useful for stress testing web applications.

## Installation
`ab` is included with the Apache HTTP server package. To install it:

### On Ubuntu/Debian:
```sh
sudo apt update && sudo apt install apache2-utils
```

### On macOS:
```sh
brew install httpd
```

### On Windows:
Download Apache binaries from [Apache Lounge](https://www.apachelounge.com/download/).

## Usage
The basic syntax for running Apache Benchmark is:
```sh
ab -n [requests] -c [concurrency] [URL]
```

### Example:
```sh
ab -n 1000 -c 10 http://example.com/
```
- `-n 1000`: Sends 1000 total requests.
- `-c 10`: Uses 10 concurrent connections.

## Output Explanation
After running `ab`, you will see output like:
```
Requests per second:   250.32 [#/sec] (mean)
Time per request:      4.00 [ms] (mean)
Transfer rate:         5120.00 [Kbytes/sec] received
```
- **Requests per second**: The number of requests the server can handle per second.
- **Time per request**: The average response time per request.
- **Transfer rate**: The rate at which data is transferred.

## Common Options
| Option | Description |
|--------|-------------|
| `-n`   | Total number of requests to perform |
| `-c`   | Number of concurrent requests |
| `-t`   | Test duration in seconds |
| `-H`   | Add custom headers |
| `-p`   | Send a POST request with a data file |
| `-A`   | Provide authentication credentials |

## Best Practices
- Run tests on a dedicated network to avoid interference.
- Test during low-traffic periods to prevent disruptions.
- Use realistic concurrency values for accurate results.

## More Information
For the full documentation, visit the [official Apache Benchmark page](https://httpd.apache.org/docs/2.4/programs/ab.html).

