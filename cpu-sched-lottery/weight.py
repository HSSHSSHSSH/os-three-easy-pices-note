
from optparse import OptionParser


arr = [
    88761, 71755, 56483, 46273, 36291,29154, 23254, 18705, 14949, 11916,
    9548, 7620, 6100, 4904, 3906,3121, 2501, 1991, 1586, 1277,1024, 820, 655, 526, 423,
    335, 272, 215, 172, 137,110, 87, 70, 56, 45,36, 29, 23, 18, 15,
]


parser = OptionParser()
parser.add_option('-n', '--number', default=0, help='the weight',  action='store', type='int', dest='number')
parser.add_option('-p', '--process', default=1, help='the count of processes',  action='store', type='int', dest='process')

(options, args) = parser.parse_args()

print('number', options.number)
print('args', args)

weightk = options.number

# 找出arr中前options.process个元素并求和
sum = 0
for i in arr[:options.process]:
    if i > weightk:
        sum += i

print('sum', sum)

print('wawa', weightk / sum)












