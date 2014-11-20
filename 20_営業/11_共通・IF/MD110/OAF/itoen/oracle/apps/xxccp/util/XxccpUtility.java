/*============================================================================
* �t�@�C���� : XxccpUtility
* �T�v����   : CCP���ʊ֐�
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-13 1.0  SCS KUME     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxccp.util;

import itoen.oracle.apps.xxccp.util.XxccpUtility2;
import itoen.oracle.apps.xxccp.util.XxccpConstants;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.domain.Date;

/***************************************************************************
 * �ړ����ʊ֐��N���X�ł��B
 * @author  SCS KUME
 * @version 1.0
 ***************************************************************************
 */
public class XxccpUtility 
{
  public XxccpUtility()
  {
  }

  /*****************************************************************************
  * SYSDATE���擾���܂��B
  * @param trans - �g�����U�N�V����
  * @return Date SYSDATE
  * @throws OAException - OA��O
  ****************************************************************************/
  public static Date getSysdate(
   OADBTransaction trans
  ) throws OAException
  {
    String apiName   = "getSysdate";
    Date   sysdate = null;

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(100);
    sb.append("BEGIN "                  );
    sb.append("   SELECT SYSDATE "      ); // SYSDATE
    sb.append("   INTO   :1 "           );
    sb.append("   FROM   DUAL; "        );
    sb.append("END; "                   );

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt
     = trans.createCallableStatement(sb.toString(), OADBTransaction.DEFAULT);
  
   try
   {
     // �p�����[�^�ݒ�(OUT�p�����[�^)
     cstmt.registerOutParameter(1, Types.DATE); // SYSDATE

     // PL/SQL���s
     cstmt.execute();
      
     // �߂�l�擾
     sysdate = new Date(cstmt.getDate(1));

   // PL/SQL���s����O�̏ꍇ
   } catch(SQLException s)
   {
     // ���[���o�b�N
     rollBack(trans);
     XxccpUtility2.writeLog(
       trans,
       XxccpConstants.CLASS_XXCCP_UTILITY + XxccpConstants.DOT + apiName,
       s.toString(),
       6);
     // �G���[���b�Z�[�W�o��
     throw new OAException(
       XxccpConstants.APPL_XXCCP, 
       XxccpConstants.XXCCP191001);
   } finally
   {
     try
     {
       //�������ɃG���[�����������ꍇ��z�肷��
       cstmt.close();
     } catch(SQLException s)
     {
       // ���[���o�b�N
       rollBack(trans);
       XxccpUtility2.writeLog(
         trans,
         XxccpConstants.CLASS_XXCCP_UTILITY + XxccpConstants.DOT + apiName,
         s.toString(),
         6);
       // �G���[���b�Z�[�W�o��
       throw new OAException(
         XxccpConstants.APPL_XXCCP, 
         XxccpConstants.XXCCP191003);
     }
   }
   return sysdate;
  } // getSysdate

  /***************************************************************************
   * ���[���o�b�N�������s�����\�b�h�ł��B
   * @param trans - �g�����U�N�V����
   ***************************************************************************
   */
   public static void rollBack(
     OADBTransaction trans
   )
   {
     // ���[���o�b�N���s
     trans.executeCommand("ROLLBACK ");
   } // rollBack
   
  /***************************************************************************
   * �R�~�b�g�������s�����\�b�h�ł��B
   * @param trans - �g�����U�N�V����
   ***************************************************************************
   */
  public static void commit(
    OADBTransaction trans
  )
  {
    // �R�~�b�g���s
    trans.executeCommand("COMMIT ");
  } // commit

}