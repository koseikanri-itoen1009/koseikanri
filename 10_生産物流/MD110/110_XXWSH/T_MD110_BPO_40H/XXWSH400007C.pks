CREATE OR REPLACE PACKAGE xxwsh400007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400007c(package)
 * Description      : �o�׈˗����ߏ���
 * MD.050           : T_MD050_BPO_401_�o�׈˗�
 * MD.070           : �o�׈˗����ߏ��� T_MD070_BPO_40H
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/4/10     1.0   R.Matusita       �V�K�쐬
 *  2008/5/19     1.1   Oracle �㌴���D  �����ύX�v��#80�Ή� �p�����[�^�u���_�v�ǉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                  OUT NOCOPY VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_order_type_id         IN  VARCHAR2,                -- �o�Ɍ`��ID
    iv_deliver_from          IN  VARCHAR2,                -- �o�׌�
    iv_sales_base            IN  VARCHAR2,                -- ���_
    iv_sales_base_category   IN  VARCHAR2,                -- ���_�J�e�S��
    iv_lead_time_day         IN  VARCHAR2,                -- ���Y����LT
    iv_schedule_ship_date    IN  VARCHAR2,                -- �o�ɓ�
    iv_base_record_class     IN  VARCHAR2,                -- ����R�[�h�敪
    iv_request_no            IN  VARCHAR2,                -- �˗�No
    iv_tighten_class         IN  VARCHAR2,                -- ���ߏ����敪
    iv_prod_class            IN  VARCHAR2,                -- ���i�敪
    iv_tightening_program_id IN  VARCHAR2,                -- ���߃R���J�����gID
    iv_instruction_dept      IN  VARCHAR2                 -- ����
  );
END xxwsh400007c;
/
