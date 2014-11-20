create or replace
PACKAGE xxwsh600006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH600006C(spec)
 * Description      : �����z�Ԕz���v��쐬�������b�N�Ή�
 * MD.050           : �z�Ԕz���v�� T_MD050_BPO_600
 * MD.070           : �����z�Ԕz���v��쐬���� T_MD070_BPO_60B
 * Version          : 1.3
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  release_lock         ���b�N�����֐�
 *  main                 ���C���֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/29   1.0   T.MIYATA    b    ����쐬
 *  2008/12/20   1.1   M.Hokkanji       �{�ԏ�Q#738
 *  2009/01/16   1.2   M.Nomura         �{�ԏ�Q#900
 *  2009/01/27   1.3   H.Itou           �{�ԏ�Q#1028
 *****************************************************************************************/
--
  -- ���C���֐�
  PROCEDURE main(
        errbuf                  OUT NOCOPY VARCHAR2,  --  �G���[�E���b�Z�[�W
        retcode                 OUT NOCOPY VARCHAR2,  --  ���^�[���E�R�[�h
        iv_prod_class           IN  VARCHAR2,         --  1.���i�敪
        iv_shipping_biz_type    IN  VARCHAR2,         --  2.�������
        iv_block_1              IN  VARCHAR2,         --  3.�u���b�N1
        iv_block_2              IN  VARCHAR2,         --  4.�u���b�N2
        iv_block_3              IN  VARCHAR2,         --  5.�u���b�N3
        iv_storage_code         IN  VARCHAR2,         --  6.�o�Ɍ�
        iv_transaction_type_id  IN  VARCHAR2,         --  7.�o�Ɍ`��ID
        iv_date_from            IN  VARCHAR2,         --  8.�o�ɓ�From
        iv_date_to              IN  VARCHAR2,         --  9.�o�ɓ�To
        iv_forwarder_id         IN  VARCHAR2,         -- 10.�^���Ǝ�ID
-- Ver1.3 H.Itou Add Start �{�ԏ�Q#1028�Ή�
        iv_instruction_dept     IN  VARCHAR2          -- 11.�w������
-- Ver1.3 H.Itou Add End
    );
END xxwsh600006c;
/
