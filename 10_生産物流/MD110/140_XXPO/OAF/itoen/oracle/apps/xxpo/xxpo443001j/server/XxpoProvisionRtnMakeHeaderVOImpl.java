/*============================================================================
* �t�@�C���� : XxpoProvisionRtnMakeHeaderVOImpl
* �T�v����   : �x���ԕi�쐬�w�b�_�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-31 1.0  �F�{ �a�Y    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo443001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �x���ԕi�쐬�w�b�_�r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �F�{ �a�Y
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRtnMakeHeaderVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionRtnMakeHeaderVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param reqNo - �˗�No
   ****************************************************************************/
  public void initQuery(String reqNo) 
  {
    // ���������t��
    setWhereClauseParam(0, reqNo);

    // �������s
    executeQuery();
  }
}