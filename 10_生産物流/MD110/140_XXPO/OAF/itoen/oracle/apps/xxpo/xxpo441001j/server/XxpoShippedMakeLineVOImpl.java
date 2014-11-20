/*============================================================================
* �t�@�C���� : XxpoShippedMakeLineVOImpl
* �T�v����   : �o�Ɏ��ѓ��͖��׃r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-31 1.0  �R�{���v     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo441001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
/***************************************************************************
 * �o�Ɏ��ѓ��͖��׃r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �R�{ ���v
 * @version 1.0
 ***************************************************************************
 */
public class XxpoShippedMakeLineVOImpl extends OAViewObjectImpl  
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoShippedMakeLineVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param exeType       - �N���^�C�v
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   ****************************************************************************/
  public void initQuery(String exeType, Number orderHeaderId)
  {
    int i = 0;
    setWhereClauseParam(i++, orderHeaderId);
    // �������s
    executeQuery();
  }
}