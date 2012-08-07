import os
import urllib2
import datetime
import re

#scrips = ['INFY', 'TCS', 'WIPRO', 'HCLTECH']
#scrips = ["ACC","AMBUJACEM","GRASIM","AXISBANK","KOTAKBANK","HDFC","HDFCBANK","ICICIBANK","BANKBARODA","SBIN","PNB","IDFC","BHARTIARTL","BHEL","CIPLA","DRREDDY","RANBAXY","SUNPHARMA","COALINDIA","BPCL","CAIRN","GAIL","ONGC","BAJAJ-AUTO","HEROMOTOCO","ASIANPAINT","HINDUNILVR","ITC","DLF","JPASSOCIAT","LT","M&M","MARUTI","TATAMOTORS","NTPC","POWERGRID","RELIANCE","RELINFRA","HINDALCO","JINDALSTEL","SAIL","SESAGOA","SIEMENS","STER","TATAPOWER","TATASTEEL","HCLTECH","INFY","TCS","WIPRO"]
scrips = []
index = 'CNX 500'

for line in open('index.csv').readlines():
	fields = line.split(';')
	if len(fields) > 3 and fields[0] == index: scrips.append(fields[1])
	
days = '15'  # Last n days of data
base_url = 'http://www.google.com/finance/getprices?q=%s&x=NSE&i=60&p=%sd&f=d,c,o,h,l,v'

out_file = open(index + '.csv', 'w') # concatenate these files as you get more data
out_file.write('scrip,date,timestamp,close,open,high,low,volume\n')

for scrip in scrips:
	print 'getting data for: ', scrip
	url = base_url % (scrip, days)    
	try:
		page = urllib2.urlopen(url).read()
		lines = page.split('\n')
		for line in lines[7:]:  # first 7 lines are preamble
			if len(line) < 4: continue # sanity check as sometimes there are blank lines
			if line.startswith('a'):
				ts 		   = int(line.split(',')[0][1:]) 
				ds = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d')
				out_line   = '%s,%s,%s\n'%(scrip, ds, line)
				out_line   = re.sub("a[0-9]*", "0", out_line)
			else:
				out_line   = '%s,%s,%s\n'%(scrip, ds, line)
			 
			out_file.write(out_line)
	except urllib2.URLError:
		print 'download failed for ', scrip
		continue

out_file.close()

