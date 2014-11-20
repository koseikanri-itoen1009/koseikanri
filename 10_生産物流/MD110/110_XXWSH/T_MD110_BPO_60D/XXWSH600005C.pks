CREATE OR REPLACE PACKAGE xxwsh600005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600005c(spec)
 * Description      : �m��u���b�N����
 * MD.050           : �o�׈˗� T_MD050_BPO_601
 * MD.070           : �m��u���b�N����  T_MD070_BPO_60D
 * Version          : 1.3
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
 *  2008/04/18    1.0  Oracle �㌴���D   ����쐬
 *  2008/06/16    1.1  Oracle �쑺���K   ������Q #9�Ή�
 *  2008/06/19    1.2  Oracle �㌴���D   ST��Q #178�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT NOCOPY VARCHAR2,  -- �G���[���b�Z�[�W #�Œ�#
    retcode                   OUT NOCOPY VARCHAR2,  -- �G���[�R�[�h     #�Œ�#
    iv_dept_code              IN VARCHAR2,          -- ����
    iv_shipping_biz_type      IN VARCHAR2,          -- �������
    iv_transaction_type_id    IN VARCHAR2,          -- �o�Ɍ`��
    iv_lead_time_day_01       IN VARCHAR2,          -- ���Y����LT1
    iv_lt1_ship_date_from     IN VARCHAR2,          -- ���Y����LT1/�o�׈˗�/�o�ɓ�From
    iv_lt1_ship_date_to       IN VARCHAR2,          -- ���Y����LT1/�o�׈˗�/�o�ɓ�To
    iv_lead_time_day_02       IN VARCHAR2,          -- ���Y����LT2
    iv_lt2_ship_date_from     IN VARCHAR2,          -- ���Y����LT2/�o�׈˗�/�o�ɓ�From
    iv_lt2_ship_date_to       IN VARCHAR2,          -- ���Y����LT2/�o�׈˗�/�o�ɓ�To
    iv_ship_date_from         IN VARCHAR2,          -- �o�ɓ�From
    iv_ship_date_to           IN VARCHAR2,          -- �o�ɓ�To
    iv_move_ship_date_from    IN VARCHAR2,          -- �ړ�/�o�ɓ�From
    iv_move_ship_date_to      IN VARCHAR2,          -- �ړ�/�o�ɓ�To
    iv_prov_ship_date_from    IN VARCHAR2,          -- �x��/�o�ɓ�From
    iv_prov_ship_date_to      IN VARCHAR2,          -- �x��/�o�ɓ�To
    iv_block_01               IN VARCHAR2,          -- �u���b�N�P
    iv_block_02               IN VARCHAR2,          -- �u���b�N�Q
    iv_block_03               IN VARCHAR2,          -- �u���b�N�R
    iv_shipped_locat_code     IN VARCHAR2           -- �o�Ɍ�
  );
END xxwsh600005c;
/
