/*============================================================================
* �t�@�C���� : XxcsoLookupListVOImpl
* �T�v����   : �N�C�b�N�R�[�h�|�b�v���X�g�p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-05 1.0  SCS����_    �V�K�쐬
* 2008-12-16 1.0  SCS����_    LOOKUP_TYPE�݂̂Ŏ擾����悤�ɏC��
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.poplist.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �N�C�b�N�R�[�h����\������|�b�v���X�g�̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoLookupListVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoLookupListVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param lookupType       ���b�N�A�b�v�^�C�v
   * @param orderBy          �\�[�g����
   *****************************************************************************
   */
  public void initQuery(
    String lookupType,
    String orderBy
  )
  {
    initQuery(lookupType, null, orderBy);
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param lookupType       ���b�N�A�b�v�^�C�v
   * @param whereStmt        ��������
   * @param orderBy          �\�[�g����
   *****************************************************************************
   */
  public void initQuery(
    String lookupType,
    String whereStmt,
    String orderBy
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    
    setWhereClauseParam(index++, lookupType);

    setWhereClause(whereStmt);
    setOrderByClause(orderBy);
  }
}