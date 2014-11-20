CREATE OR REPLACE PACKAGE xxwsh400001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH400001C(spec)
 * Description      : ����v�悩��̃��[�t�o�׈˗������쐬
 * MD.050/070       : �o�׈˗�                              (T_MD050_BPO_400)
 *                    ����v�悩��̃��[�t�o�׈˗������쐬  (T_MD070_BPO_40A)
 * Version          : 1.5
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
 *  2008/03/04    1.0   Tatsuya Kurata    main�V�K�쐬
 *  2008/04/17    1.1   Tatsuya Kurata    �����ύX�v��#40,#42,#45�Ή�
 *  2008/04/30    1.2   Tatsuya Kurata    �����ύX�v��#65�Ή�
 *  2008/06/04    1.3   Tatsuya Kurata   �s��C��
 *  2008/06/10    1.4   �Γn  ���a       �s��C��(�G���[���X�g�ŃX�y�[�X���߂��폜�j
 *                                       xxwsh_common910_pkg�̋A��l������C��
 *  2008/06/19    1.5   Y.Shindou        �����ύX�v��#143�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main
    (
     errbuf      OUT    VARCHAR2       -- �G���[���b�Z�[�W
    ,retcode     OUT    VARCHAR2       -- �G���[�R�[�h
    ,iv_yyyymm   IN     VARCHAR2       -- 01.�Ώ۔N��
    ,iv_base     IN     VARCHAR2       -- 02.�Ǌ����_
    );
END xxwsh400001c;
/
