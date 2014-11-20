/*============================================================================
* �t�@�C���� : XxcsoQtApTaxRateVOImpl
* �T�v����   : �����ŗ��擾�p�r���[�N���X
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2011-05-17 1.0  SCS�ː��a�K  �V�K�쐬
* 2013-08-20 1.1  SCSK����O�� �yE_�{�ғ�_10884�z����ő��őΉ�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
// 2013-08-20 Ver1.1 [E_�{�ғ�_10884] Add Start
import oracle.jbo.domain.Date;
// 2013-08-20 Ver1.1 [E_�{�ғ�_10884] Add End
/*******************************************************************************
 * �����ŗ��擾�̃r���[�N���X�ł��B
 * @author  SCS�ː��a�K
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQtApTaxRateVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQtApTaxRateVOImpl()
  {
  }
// 2013-08-20 Ver1.1 [E_�{�ғ�_10884] Add Start
  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param getDate ����Ŏ擾���
   *****************************************************************************
   */
  public void initQuery(
    Date getDate
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, getDate);

    executeQuery();

  }
// 2013-08-20 Ver1.1 [E_�{�ғ�_10884] Add End
}