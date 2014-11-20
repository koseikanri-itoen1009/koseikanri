CREATE OR REPLACE PACKAGE xxwsh400011c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400011c(spec)
 * Description      : �o�׈˗����ߋN������
 * MD.050           : T_MD050_BPO_401_�o�׈˗�
 * MD.070           : �o�׈˗����ߏ��� T_MD070_BPO_40H
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 ���C���֐�
 *
 *  Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/16   1.0   T.Ohashi         ����쐬
 *  2009/02/23   1.1   M.Nomura         �{��#1176�Ή��i�ǉ��C���j
 *
 *****************************************************************************************/
--
  -- ���C���֐�
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2,        --  �G���[�E���b�Z�[�W
    retcode                  OUT NOCOPY VARCHAR2,        --  ���^�[���E�R�[�h
    iv_order_type_id         IN  VARCHAR2,               --  1.�o�Ɍ`��ID
    iv_deliver_from          IN  VARCHAR2,               --  2.�o�׌�
    iv_sales_base            IN  VARCHAR2,               --  3.���_
    iv_sales_base_category   IN  VARCHAR2,               --  4.���_�J�e�S��
    iv_lead_time_day         IN  VARCHAR2,               --  5.���Y����LT
    iv_schedule_ship_date    IN  VARCHAR2,               --  6.�o�ɓ�
    iv_base_record_class     IN  VARCHAR2,               --  7.����R�[�h�敪
    iv_request_no            IN  VARCHAR2,               --  8.�˗�No
    iv_tighten_class         IN  VARCHAR2,               --  9.���ߏ����敪
    iv_prod_class            IN  VARCHAR2,               -- 10.���i�敪
    iv_tightening_program_id IN  VARCHAR2,               -- 11.���߃R���J�����gID
    iv_instruction_dept      IN  VARCHAR2                -- 12.����
    );
END xxwsh400011c;
/
