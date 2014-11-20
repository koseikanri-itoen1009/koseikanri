/*============================================================================
* �t�@�C���� : XxwshLineVOImpl
* �T�v����   : ���o�׎��у��b�g���͉�ʃr���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-27 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * ���o�׎��у��b�g���͉�ʃr���[�I�u�W�F�N�g�ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxwshLineVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshLineVOImpl()
  {
  }
  
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param orderLineId  - �󒍖��׃A�h�I��ID
   * @param calledKbn    - �ďo��ʋ敪
   ****************************************************************************/
  public void initQuery(
    String      orderLineId,
    String      calledKbn
    )
  {
    // ������
    setWhereClauseParams(null);
          
    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, calledKbn);
    setWhereClauseParam(1, calledKbn);
    setWhereClauseParam(2, calledKbn);
    setWhereClauseParam(3, orderLineId);
  
    // SELECT�����s
    executeQuery();
  }
}