# CẤU TRÚC THƯ MỤC


## Danh sách thư mục

```bash
├── bin
├── conf
├── data
│   ├── ips
│   ├── templates
│   └── users
├── docs
│   └── Cấu trúc thư mục.md
├── func
└── README.md
```

| path    | ý nghĩa |
|---------|---------|
| bin     | Chứa các file thực hiện action được lựa chọn ở menu. Các file này cũng có dùng để gọi chạy trực tiếp với các tham số tương ứng|
| conf    | Chứa các file config giúp script hoạt động |
| data    | Chứa dữ liệu giúp đảm bảo việc chạy adhoc bằng các script trong /bin và chạy qua menu được đồng bộ hóa với nhau|
| data/ips | Danh sách IP public của server |
| data/templates | Danh sách các template dùng cho việc generate file config |
| data/users | Dữ liệu của các users |
| docs | Tài liệu |
| func | Các helper function sẽ được include vào các file action trong /bin |

