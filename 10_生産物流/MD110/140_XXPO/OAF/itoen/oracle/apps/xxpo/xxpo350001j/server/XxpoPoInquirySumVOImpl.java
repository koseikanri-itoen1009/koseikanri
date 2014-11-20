/*============================================================================
* �t�@�C���� : XxpoPoInquirySumVOImpl
* �T�v����   : �����E����Ɖ���/����������v�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-13 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �����E����Ɖ���/����������v�r���[�I�u�W�F�N�g�ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxpoPoInquirySumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoPoInquirySumVOImpl()
  {
  }

  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchStatusCode     - �����X�e�[�^�X
   * @param searchHeaderId       - �����w�b�_ID
   ****************************************************************************/
  public void initQuery(
    String searchStatusCode,
    String searchHeaderId
    )
  {
    // ������
    setWhereClauseParams(null);
          
    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, searchStatusCode);
    setWhereClauseParam(1, searchStatusCode);
    setWhereClauseParam(2, searchStatusCode);
    setWhereClauseParam(3, searchStatusCode);
    setWhereClauseParam(4, searchHeaderId);
    
    // SELECT�����s
    executeQuery();
  }
}