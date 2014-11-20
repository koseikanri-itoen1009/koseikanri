/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcBulkUpdateConstants
* �T�v����   : ���[�gNo/�S���c�ƈ��ꊇ�X�V��ʋ��ʌŒ�l�N���X
* �o�[�W���� : 1.2
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS�x���a��  �V�K�쐬
* 2009-03-05 1.1  SCS�������l  [CT1-034]�d���c�ƈ��G���[�Ή�
* 2010-03-23 1.2  SCS�������  [E_�{�ғ�_01942]�Ǘ������_�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.util;

/*******************************************************************************
 * �A�h�I���F���[�gNo/�S���c�ƈ��ꊇ�X�V��ʂ̌Œ�l�N���X�ł��B
 * @author  SCS�x���a��
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateConstants 
{
  public static final String MODE_FIRE_ACTION        = "FireAction";

  public static final String[] CENTERING_OBJECTS =
  {
// 2010-03-23 [E_�{�ғ�_01942] Add Start
    "BaseCodeLayout",
// 2010-03-23 [E_�{�ғ�_01942] Add End
    "ResourceLayout"
  };
  
  public static final String TOKEN_VALUE_PROCESS = "���[�gNo�^�c�ƈ��ꊇ�X�V";

// 2010-03-23 [E_�{�ғ�_01942] Add Start
  public static final String TOKEN_VALUE_BASECODE       = "���_�b�c";
// 2010-03-23 [E_�{�ғ�_01942] Add End
  public static final String TOKEN_VALUE_EMPLOYEENUMBER = "�c�ƈ��R�[�h";
  public static final String TOKEN_VALUE_ROUTENO        = "���[�gNo";
  public static final String TOKEN_VALUE_REFLECTMETHOD  = "���f���@";
  public static final String TOKEN_VALUE_ACCOUNTNUMBER  = "�ڋq�R�[�h";
  public static final String TOKEN_VALUE_PARTYNAME      = "�ڋq��";
  public static final String TOKEN_VALUE_TRGTRESOURCE   = "���S��";
  public static final String TOKEN_VALUE_TRGTROUTENO    = "�����[�gNo";
  public static final String TOKEN_VALUE_NEXTRESOURCE   = "�V�S��";
  public static final String TOKEN_VALUE_NEXTROUTENO    = "�V���[�gNo";
  public static final String TOKEN_VALUE_ACCOUNT_INFO   = "�ڋq���";

  public static final String MAPKEY_ACCOUNTNUMBER       = "ACCOUNTNUMBER";
  public static final String MAPKEY_PARTYNAME           = "PARTYNAME";

  public static final String BOOL_ISRSV                 = "Y";
  public static final String BOOL_ISNOTRSV              = "N";

  public static final String REFLECT_TRGT               = "1";
  public static final String REFLECT_RSV                = "2";
}