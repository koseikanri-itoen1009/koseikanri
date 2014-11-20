CREATE OR REPLACE PACKAGE xxwsh400006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400006c(spec)
 * Description      : �o�׈˗��m�菈��
 * MD.050           : T_MD050_BPO_401_�o�׈˗�
 * MD.070           : �o�׈˗��m�菈�� T_MD070_EDO_BPO_40G
 * Version          : 1.4
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
 *  2008/3/24     1.0   R.Matusita       �V�K�쐬
 *  2008/4/23     1.1   R.Matusita       �����ύX�v��#63
 *  2009/4/20     1.3   Y.Kazama         �{�ԏ�Q#1398�Ή�
 *  2009/4/20     1.4   M.Miyagawa       �{�ԏ�Q#1671�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                  OUT NOCOPY VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_prod_class            IN  VARCHAR2,                -- ���i�敪
    iv_head_sales_branch     IN  VARCHAR2,                -- �Ǌ����_
    iv_input_sales_branch    IN  VARCHAR2,                -- ���͋��_
    iv_deliver_to_id         IN  VARCHAR2,                -- �z����ID
    iv_request_no            IN  VARCHAR2,                -- �˗�No
    iv_schedule_ship_date    IN  VARCHAR2,                -- �o�ɓ�
    iv_schedule_arrival_date IN  VARCHAR2,                -- ����
    iv_status_kbn            IN  VARCHAR2                 -- ���߃X�e�[�^�X�`�F�b�N�敪
  );
END xxwsh400006c;
/
