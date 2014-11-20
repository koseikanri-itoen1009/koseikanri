/*============================================================================
* �t�@�C���� : XxinvMovementResultsVOImpl
* �T�v����   : ���o�Ɏ��їv��:�����r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-12 1.0  �勴�F�Y     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510001j.server;
import com.sun.java.util.collections.HashMap;
import java.util.ArrayList;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

/***************************************************************************
 * �����r���[�I�u�W�F�N�g�ł��B
 * @author  ORACLE �勴 �F�Y
 * @version 1.0
 ***************************************************************************
 */
public class XxinvMovementResultsVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvMovementResultsVOImpl()
  {
  }

  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchParams �����p�����[�^�pHashMap
   ****************************************************************************/
   public void initQuery(
    HashMap searchParams         // �����L�[�p�����[�^
   )
   {
     StringBuffer whereClause = new StringBuffer(1000);  // WHERE��쐬�p�I�u�W�F�N�g
     ArrayList parameters = new ArrayList();             // �o�C���h�ϐ��ݒ�l
     int bindCount = 0;

     // ������
     setWhereClauseParams(null);

     // ���������擾
     String movNum              = (String)searchParams.get("movNum");              // �ړ��ԍ�
     String movType             = (String)searchParams.get("movType");             // �ړ��^�C�v
     String status              = (String)searchParams.get("status");              // �X�e�[�^�X
     String shippedLocatId      = (String)searchParams.get("shippedLocatId");      // �o�Ɍ�
     String shipToLocatId       = (String)searchParams.get("shipToLocatId");       // ���ɐ�
     String shipDateFrom        = (String)searchParams.get("shipDateFrom");        // �o�ɓ�(�J�n)
     String shipDateTo          = (String)searchParams.get("shipDateTo");          // �o�ɓ�(�I��)
     String arrivalDateFrom     = (String)searchParams.get("arrivalDateFrom");     // ����(�J�n)
     String arrivalDateTo       = (String)searchParams.get("arrivalDateTo");       // ����(�I��)
     String instructionPostCode = (String)searchParams.get("instructionPostCode"); // �ړ��w������
     String deliveryNo          = (String)searchParams.get("deliveryNo");          // �z��No
     String peopleCode          = (String)searchParams.get("peopleCode");          // �]�ƈ��敪
     String actualFlag          = (String)searchParams.get("actualFlag");          // ���уf�[�^�敪
     String productFlag         = (String)searchParams.get("productFlag");         // ���i���ʋ敪

     // *************************** //
    // *        �����쐬         * //
    // *************************** //

    //���̓p�����[�^�̐��i���ʋ敪���u1�v(���i)�̏ꍇ
    if ("1".equals(productFlag))
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND product_flg = '1'");

      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" product_flg = '1'");
      }
    //���̓p�����[�^�̐��i���ʋ敪���u2�v(���i�ȊO)�̏ꍇ
    } else if ("2".equals(productFlag))
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND product_flg = '2'");

      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" product_flg = '2'");
      }
    }

    //�ړ��ԍ������͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(movNum))
    {
     // �����ǉ�1���ڈȍ~�̏ꍇ
     if (whereClause.length() != 0)
     {
       whereClause.append(" AND mov_num = :" + bindCount);

     // �����ǉ�1���ڂ̏ꍇ
     } else
     {
       whereClause.append(" mov_num = :" + bindCount);
     }
     //�o�C���h�ϐ����J�E���g
     bindCount = bindCount + 1;
     //�����l���Z�b�g
     parameters.add(movNum);
    }

    //�ړ��^�C�v�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(movType))
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND mov_type = :" + bindCount);

      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" mov_type = :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(movType);
    }

    //�X�e�[�^�X�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(status))
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND status = :" + bindCount);

      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" status = :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(status);
    }

    //�o�Ɍ������͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(shippedLocatId))
    {
      // �]�ƈ��敪��1:�������[�U�̏ꍇ
      // ���͏]�ƈ��敪��2:�O�����[�U�����̓p�����[�^�̎��уf�[�^�敪��1(�o��)�̏ꍇ
     if (XxinvConstants.PEOPLE_CODE_I.equals(peopleCode) || ((XxinvConstants.PEOPLE_CODE_O.equals(peopleCode)) && ("1".equals(actualFlag))))
     {
       
       // �����ǉ�1���ڈȍ~�̏ꍇ
       if (whereClause.length() != 0)
       {
         whereClause.append(" AND shipped_locat_id = :" + bindCount);

       // �����ǉ�1���ڂ̏ꍇ
       } else
       {
         whereClause.append(" shipped_locat_id = :" + bindCount);
       }
       //�o�C���h�ϐ����J�E���g
       bindCount = bindCount + 1;
       //�����l���Z�b�g
       parameters.add(shippedLocatId);
      }
    }

    //���ɐ悪���͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(shipToLocatId))
    {
      // �]�ƈ��敪��1:�������[�U�̏ꍇ
      // ���͏]�ƈ��敪��2:�O�����[�U�����̓p�����[�^�̎��уf�[�^�敪��2(����)�̏ꍇ
      if (XxinvConstants.PEOPLE_CODE_I.equals(peopleCode) 
        || ((XxinvConstants.PEOPLE_CODE_O.equals(peopleCode)) 
        && ("2".equals(actualFlag))))
      {
      
        // �����ǉ�1���ڈȍ~�̏ꍇ
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND ship_to_locat_id = :" + bindCount);

        // �����ǉ�1���ڂ̏ꍇ
        } else
        {
          whereClause.append(" ship_to_locat_id = :" + bindCount);
        }
        //�o�C���h�ϐ����J�E���g
        bindCount = bindCount + 1;
        //�����l���Z�b�g
        parameters.add(shipToLocatId);
      }
    }

    //�o�ɓ�FROM�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(shipDateFrom))
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND schedule_ship_date >= :" + bindCount);

      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" schedule_ship_date >= :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(shipDateFrom);
    }

    //�o�ɓ�TO�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(shipDateTo))
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND schedule_ship_date <= :" + bindCount);

      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" schedule_ship_date <= :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(shipDateTo);
    }

    //����FROM�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(arrivalDateFrom))
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND schedule_arrival_date >= :" + bindCount);

      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" schedule_arrival_date >= :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(arrivalDateFrom);
    }

    //����TO�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(arrivalDateTo))
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND schedule_arrival_date <= :" + bindCount);

      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" schedule_arrival_date <= :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(arrivalDateTo);
    }

    //�ړ��w�����������͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(instructionPostCode))
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND instruction_post_code = :" + bindCount);

      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" instruction_post_code = :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(instructionPostCode);
    }

    //�z��No�����͂���Ă����ꍇ
    if (!XxcmnUtility.isBlankOrNull(deliveryNo))
    {
      // �����ǉ�1���ڈȍ~�̏ꍇ
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND delivery_no = :" + bindCount);

      // �����ǉ�1���ڂ̏ꍇ
      } else
      {
        whereClause.append(" delivery_no = :" + bindCount);
      }
      //�o�C���h�ϐ����J�E���g
      bindCount = bindCount + 1;
      //�����l���Z�b�g
      parameters.add(deliveryNo);
    }


    // ����������VO�ɃZ�b�g
    setWhereClause(whereClause.toString());

    // �o�C���h�l���ݒ肳��Ă����ꍇ
    if (bindCount > 0)
    {
      // �����l�z����擾
      Object[] params = new Object[bindCount];
      params = parameters.toArray();
      // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
      setWhereClauseParams(params);

    }
    executeQuery();
   }
}