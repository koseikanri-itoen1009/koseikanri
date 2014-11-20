/*============================================================================
* �t�@�C���� : XxcsoBaseSearchVOImpl
* �T�v����   : ���_���擾�p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-02-20 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * ���_�����擾���邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoBaseSearchVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoBaseSearchVOImpl()
  {
  }


  public void initQuery(
    String baseCode
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, baseCode);

    executeQuery();
  }
}