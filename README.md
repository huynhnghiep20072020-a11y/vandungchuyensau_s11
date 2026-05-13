# BÁO CÁO BÀI TẬP [VẬN DỤNG CHUYÊN SÂU] - TÍNH CHI PHÍ XUẤT VIỆN TỰ ĐỘNG

**Vai trò:** Database Developer  
**Bối cảnh:** Tự động hóa module tính toán chi phí xuất viện nhằm khắc phục tình trạng tính toán thủ công gây sai sót, thất thoát doanh thu và đảm bảo tính chính xác tuyệt đối trong giao dịch tài chính của phòng khám.

---

## 1. Xác định Dữ liệu I/O & Đề xuất Tham số

Để hệ thống vừa nhận được dữ liệu gốc từ thu ngân, vừa trả ngược lại kết quả tính toán mà không làm mất dấu vết dữ liệu, cấu trúc tham số được đề xuất như sau:

* **Dữ liệu đầu vào (Sử dụng tham số `IN`):**
    * `p_total_cost` (DECIMAL): Tổng chi phí gốc.
    * `p_patient_type` (VARCHAR): Diện bệnh nhân ('BHYT', 'VIP', 'THUONG').
    * *Lý do:* Tham số `IN` đảm bảo Procedure chỉ "đọc" dữ liệu từ thu ngân đẩy vào để làm nguyên liệu tính toán, không ghi đè làm mất con số gốc (phục vụ đối soát kế toán sau này).
* **Dữ liệu đầu ra (Sử dụng tham số `OUT`):**
    * `p_final_fee` (DECIMAL): Số tiền cuối cùng bệnh nhân phải thanh toán.
    * `p_status_message` (VARCHAR): Thông báo trạng thái hiển thị lên màn hình.
    * *Lý do:* Tham số `OUT` đóng vai trò như biến chứa kết quả, Backend sẽ truyền các biến rỗng vào để Procedure "hứng" kết quả trả về.

*(Lưu ý: Không dùng `INOUT` cho biến chi phí vì môi trường tài chính y tế cần sự tách bạch rõ ràng giữa "Tiền gốc" và "Tiền sau giảm trừ").*

---

## 2. Giải pháp & Các bước thực hiện

Quy trình nghiệp vụ được đóng gói bằng cấu trúc rẽ nhánh `IF - ELSEIF` qua 3 bước:

* **Bước 1 (Chốt chặn Validation):** Kiểm tra `p_total_cost`. Nếu `< 0`, lập tức gán `p_final_fee = 0`, xuất thông báo "Lỗi: Chi phí không hợp lệ" và bỏ qua các bước tính toán phía dưới.
* **Bước 2 (Phân loại & Tính toán):** Nếu chi phí hợp lệ, hệ thống kiểm tra `p_patient_type`:
    * Nếu là `'BHYT'`: `p_final_fee` = 20% tổng chi phí.
    * Nếu là `'VIP'`: `p_final_fee` = 90% tổng chi phí.
    * Nếu là `'THUONG'`: `p_final_fee` = 100% tổng chi phí.
    * *(Trường hợp ngoại lệ: Nếu nhập sai mã diện bệnh nhân, hệ thống tự động thu 100% để chống thất thoát).*
* **Bước 3 (Hoàn tất):** Gán `p_status_message` = "Đã tính toán xong" và trả kết quả về Backend.

---

## 3. Triển khai Mã nguồn SQL

```sql
-- Xóa thủ tục nếu đã tồn tại để tránh lỗi khởi tạo
DROP PROCEDURE IF EXISTS CalculateHospitalFee;

DELIMITER //

CREATE PROCEDURE CalculateHospitalFee(
    IN p_total_cost DECIMAL(18,2),
    IN p_patient_type VARCHAR(20),
    OUT p_final_fee DECIMAL(18,2),
    OUT p_status_message VARCHAR(255)
)
BEGIN
    -- Bước 1: Kiểm tra dữ liệu đầu vào không hợp lệ (Bẫy số âm)
    IF p_total_cost < 0 THEN
        SET p_final_fee = 0;
        SET p_status_message = 'Lỗi: Chi phí không hợp lệ';
    ELSE
        -- Bước 2: Rẽ nhánh tính toán dựa trên diện bệnh nhân
        IF p_patient_type = 'BHYT' THEN
            SET p_final_fee = p_total_cost * 0.2;
            
        ELSEIF p_patient_type = 'VIP' THEN
            SET p_final_fee = p_total_cost * 0.9;
            
        ELSEIF p_patient_type = 'THUONG' THEN
            SET p_final_fee = p_total_cost;
            
        ELSE
            -- Default Fallback: Tính giá gốc nếu nhập sai diện bệnh nhân
            SET p_final_fee = p_total_cost;
        END IF;
        
        -- Bước 3: Đóng gói thông báo thành công
        SET p_status_message = 'Đã tính toán xong';
    END IF;
END //

DELIMITER ;
