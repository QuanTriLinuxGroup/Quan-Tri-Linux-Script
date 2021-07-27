# QUY TẮC VIẾT CODE

## Mục tiêu
Nhằm giúp thống nhất các viết code giữa các developers và giữ cho project có tính đồng bộ

## Quy tắc đặt tên

- Đặt tên gợi tả được mục đích của fucntion/variable, tiếng anh và không dài quá 30 ký tự.

| Type          | Bad           | Good          |
|---------------|---------------|---------------|
| file name     | ThisIsFilename.sh| this_is_filename.sh |
| Global variable | GlobalVar=1 | GLOBAL_VAR=1 |
| Local variable | LocalVar=1   | local_var=1 |
| function | function GenConfig() { ... } | gen_config() { ... } |

## if, for, while

- Khi sử dụng hàm, các directive "then", "do" nằm trên cùng 1 dòng với if, for và while
- Ví dụ:
```bash
if [ $x = 'something' ]; then
    echo "$x"
fi
           
for i in 1 2 3; do
    echo $i
done
                   
while [ $# -gt 0 ]; do
    echo $1
    shift
done
```

## Kiểm tra giá trị của chuỗi

- Khi kiểm tra giá trị của chuỗi, không so sánh với chuỗi với '' hoặc "". Sử dụng test operator -n (non-zero-length string) và -z (zero-length string)
- Ví dụ:
```bash
if [ -z "$foo" ]; then
    echo 'you forgot to set $foo'
fi

if [ -n "$BASEDIR" ]; then
    echo "\$BASEDIR is set to $BASEDIR"
fi
```

## Cấu trúc một file action
- Mỗi file action sẽ bao gồm 4 section theo thứ tự:
  - Khai báo biến và hàm
  - Verify argument
  - Thực hiện action
  - Update data
- Mỗi section sẽ được phân biệt bằng một frame comment ở đầu ví dụ như sau:  
        #----------------------------------------------------------#  
        #                    Variable&Function                     #  
        #----------------------------------------------------------#  
        