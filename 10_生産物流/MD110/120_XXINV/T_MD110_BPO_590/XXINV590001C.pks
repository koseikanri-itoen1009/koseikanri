CREATE OR REPLACE PACKAGE xxinv590001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv590001c(spec)
 * Description      : OPM�݌ɉ�v���ԃI�[�v��
 * MD.050           : OPM�݌ɉ�v���ԃI�[�v��(�N���[�Y) T_MD050_BPO_590
 * MD.070           : OPM�݌ɉ�v���ԃI�[�v��(59A) T_MD070_BPO_59A
 * Version          : 1.0
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
 *  2008/08/06    1.0   Y.Suzuki         �V�K�쐬
 *
 *****************************************************************************************/
--
  -- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_sequence     IN     VARCHAR2,         -- �V�[�P���XID
    iv_fiscal_year  IN     VARCHAR2,         -- ��v�N�x
    iv_period       IN     VARCHAR2,         -- ����
    iv_period_id    IN     VARCHAR2,         -- ����ID
    iv_start_date   IN     VARCHAR2,         -- �J�n���t
    iv_end_date     IN     VARCHAR2,         -- �I�����t
    iv_op_code      IN     VARCHAR2,         -- Operators Idenrifier Number
    iv_orgn_code    IN     VARCHAR2,         -- ��ЃR�[�h
    iv_close_ind    IN     VARCHAR2          -- �����敪(1:OPEN)
  );
END xxinv590001c;
/
